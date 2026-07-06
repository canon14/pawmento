import Foundation
import Supabase

// Fix C1: DONE in I2 — API keys removed, all calls go through ai-proxy Edge Function.
// Fix C5: Made AICoachClient a final class with immutable config.
// Provider is no longer mutable shared state — it's Anthropic-only via the proxy.

/// Typed errors surfaced to the UI layer for actionable handling.
enum AICoachError: LocalizedError, Equatable {
    case authenticationRequired
    case quotaExhausted
    case serverError(statusCode: Int, message: String)
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Your session has expired. Please sign in again."
        case .quotaExhausted:
            return "You've used all your free coach questions for this period."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .noContent:
            return "No content received from AI provider"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationRequired:
            return "Sign in again to continue using the AI Coach."
        default:
            return nil
        }
    }
}

final class AICoachClient: Sendable {
    static let shared = AICoachClient()
    
    private init() {}
    
    // Fix C2: Dedicated URLSession with timeout from AIConfig
    private static let proxySession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AIConfig.requestTimeout
        config.timeoutIntervalForResource = AIConfig.requestTimeout * 3 // 90s for full resource
        return URLSession(configuration: config)
    }()
    
    /// Generates advice from the AI Coach using SSE streaming via the proxy.
    /// - Parameters:
    ///   - messages: Chat history as role/content dicts
    ///   - systemPrompt: System prompt (default: pet-less; CoachViewModel passes buildPrompt(for:))
    func streamAdvice(messages: [[String: String]], systemPrompt: String = AICoachPrompt.systemPrompt) -> AsyncThrowingStream<String, Error> {
        return streamViaProxy(messages: messages, systemPrompt: systemPrompt)
    }
    
    // MARK: - Supabase Edge Function Proxy
    
    private func streamViaProxy(messages: [[String: String]], systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream<String, Error> { continuation in
            Task {
                var lastError: Error?
                var hasYieldedContent = false
                
                for attempt in 0..<AIConfig.maxRetries {
                    do {
                        try await self.executeStream(
                            messages: messages,
                            systemPrompt: systemPrompt,
                            continuation: continuation,
                            hasYieldedContent: &hasYieldedContent
                        )
                        return
                    } catch {
                        lastError = error
                        
                        guard Self.shouldRetryStream(
                            after: error,
                            hasYieldedContent: hasYieldedContent,
                            attempt: attempt,
                            maxAttempts: AIConfig.maxRetries
                        ) else {
                            continuation.finish(throwing: error)
                            return
                        }
                        
                        let backoff = 0.5 * pow(2.0, Double(attempt))
                        try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    }
                }
                
                continuation.finish(throwing: lastError ?? URLError(.timedOut))
            }
        }
    }
    
    /// Retry is only safe before any content has been delivered to the consumer.
    static func shouldRetryStream(
        after error: Error,
        hasYieldedContent: Bool,
        attempt: Int,
        maxAttempts: Int
    ) -> Bool {
        guard !hasYieldedContent else { return false }
        guard attempt < maxAttempts - 1 else { return false }
        return isRetryableError(error)
    }
    
    private func executeStream(
        messages: [[String: String]],
        systemPrompt: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation,
        hasYieldedContent: inout Bool
    ) async throws {
        let proxyURL = URL(string: "\(Secrets.supabaseURL)/functions/v1/ai-proxy")!
        var request = URLRequest(url: proxyURL)
        request.httpMethod = "POST"
        request.timeoutInterval = AIConfig.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Auth: user's Supabase session token — short-circuit if missing
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            throw AICoachError.authenticationRequired
        }
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        
        // Fix C5: Provider is no longer mutable — Anthropic-only via proxy
        let body: [String: Any] = [
            "model": AIConfig.haikuModel,
            "max_tokens": AIConfig.maxResponseTokens,
            "system": systemPrompt,
            "messages": messages,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (result, response) = try await Self.proxySession.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            var errorBody = ""
            for try await line in result.lines {
                errorBody += line
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            
            if statusCode == 429 {
                throw AICoachError.quotaExhausted
            }
            
            if let data = errorBody.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = json["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                throw NSError(domain: "AIProxy", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(message)"])
            } else {
                throw NSError(domain: "AIProxy", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error (\(statusCode))"])
            }
        }
        
        // Fix C3/C4: Track tokens yielded for zero-token guard
        var tokensYielded = 0
        
        for try await line in result.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = line.dropFirst(6)
            
            // Handle OpenAI-style [DONE]
            if jsonString == "[DONE]" { break }
            
            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            
            if let type = json["type"] as? String {
                switch type {
                case "content_block_delta":
                    // Fix C3: Normal content delta
                    if let delta = json["delta"] as? [String: Any],
                       let text = delta["text"] as? String {
                        continuation.yield(text)
                        hasYieldedContent = true
                        tokensYielded += 1
                    }
                    
                case "message_delta":
                    // Fix C3: Check for stop_reason == "max_tokens" (truncation)
                    if let delta = json["delta"] as? [String: Any],
                       let stopReason = delta["stop_reason"] as? String,
                       stopReason == "max_tokens" {
                        // Signal truncation to the user
                        continuation.yield("\n\n_(Response was truncated due to length. Ask a follow-up to continue.)_")
                        hasYieldedContent = true
                    }
                    
                case "error":
                    // Fix C3: Handle mid-stream error events (e.g. overloaded_error)
                    let errorMessage: String
                    if let errorObj = json["error"] as? [String: Any],
                       let msg = errorObj["message"] as? String {
                        errorMessage = msg
                    } else {
                        errorMessage = "Stream error from provider"
                    }
                    throw NSError(domain: "AIProxy", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    
                case "message_stop":
                    break
                    
                default:
                    // Ignore other event types (message_start, content_block_start, ping, etc.)
                    break
                }
            }
            // OpenAI format (fallback if proxy ever changes)
            else if let choices = json["choices"] as? [[String: Any]],
                    let firstChoice = choices.first,
                    let delta = firstChoice["delta"] as? [String: Any],
                    let content = delta["content"] as? String {
                continuation.yield(content)
                hasYieldedContent = true
                tokensYielded += 1
            }
            // Fix C4: Detect top-level error object in a data line
            else if let errorObj = json["error"] as? [String: Any] {
                let message = errorObj["message"] as? String ?? "Unknown stream error"
                throw NSError(domain: "AIProxy", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
            }
        }
        
        // Fix C4: Zero-token guard — if we got 200 but yielded nothing, that's an error
        if tokensYielded == 0 {
            throw AICoachError.noContent
        }
        
        continuation.finish()
    }
    
    // MARK: - Retry Helpers
    
    private static func isRetryableError(_ error: Error) -> Bool {
        // Timeout errors
        if let urlError = error as? URLError {
            return urlError.code == .timedOut || urlError.code == .networkConnectionLost
        }
        // 429 (rate limit) or 5xx (server error) from proxy
        if let coachError = error as? AICoachError, coachError == .quotaExhausted {
            return false
        }
        if let nsError = error as? NSError, nsError.domain == "AIProxy" {
            let code = nsError.code
            return code == 429 || (code >= 500 && code < 600)
        }
        return false
    }
}
