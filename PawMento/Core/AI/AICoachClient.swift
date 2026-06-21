import Foundation
import Supabase

enum AIProvider {
    case openai
    case anthropic
}

class AICoachClient {
    static let shared = AICoachClient()
    
    // Defaulting to Anthropic Haiku for cost efficiency as per spec
    var provider: AIProvider = .anthropic
    
    // Fix I2: API keys removed from client bundle. All LLM calls go through
    // the Supabase Edge Function proxy which holds keys server-side.
    
    private init() {}
    
    /// Generates advice from the AI Coach using SSE streaming
    func streamAdvice(messages: [[String: String]], systemPrompt: String = AICoachPrompt.systemPrompt) -> AsyncThrowingStream<String, Error> {
        // Fix I2: Both providers now route through the same proxy
        return streamViaProxy(messages: messages, systemPrompt: systemPrompt)
    }
    
    // MARK: - Supabase Edge Function Proxy (Fix I2)
    // All LLM requests go through the ai-proxy Edge Function which:
    // 1. Verifies the user's Supabase auth token
    // 2. Enforces subscription/quota limits
    // 3. Holds API keys server-side (never shipped in the client bundle)
    // 4. Proxies SSE streaming responses back to the client
    
    private func streamViaProxy(messages: [[String: String]], systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        let currentProvider = provider
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    let proxyURL = URL(string: "\(Secrets.supabaseURL)/functions/v1/ai-proxy")!
                    var request = URLRequest(url: proxyURL)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Auth: user's Supabase session token
                    if let session = try? await SupabaseManager.shared.client.auth.session {
                        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                    }
                    
                    let providerName: String
                    let modelName: String
                    
                    switch currentProvider {
                    case .anthropic:
                        providerName = "anthropic"
                        modelName = AIConfig.haikuModel
                    case .openai:
                        providerName = "openai"
                        modelName = "gpt-4o-mini"
                    }
                    
                    let body: [String: Any] = [
                        "provider": providerName,
                        "model": modelName,
                        "max_tokens": 1024,
                        "system": systemPrompt,
                        "messages": messages,
                        "stream": true
                    ]
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (result, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        var errorBody = ""
                        for try await line in result.lines {
                            errorBody += line
                        }
                        if let data = errorBody.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errorObj = json["error"] as? [String: Any],
                           let message = errorObj["message"] as? String {
                            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
                            continuation.finish(throwing: NSError(domain: "AIProxy", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(message)"]))
                        } else {
                            continuation.finish(throwing: URLError(.badServerResponse))
                        }
                        return
                    }
                    
                    // The proxy streams back SSE events in the provider's native format
                    for try await line in result.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = line.dropFirst(6)
                        
                        // Handle OpenAI-style [DONE]
                        if jsonString == "[DONE]" { break }
                        
                        guard let data = jsonString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
                        
                        // Anthropic format
                        if let type = json["type"] as? String {
                            if type == "content_block_delta",
                               let delta = json["delta"] as? [String: Any],
                               let text = delta["text"] as? String {
                                continuation.yield(text)
                            } else if type == "message_stop" {
                                break
                            }
                        }
                        // OpenAI format
                        else if let choices = json["choices"] as? [[String: Any]],
                                let firstChoice = choices.first,
                                let delta = firstChoice["delta"] as? [String: Any],
                                let content = delta["content"] as? String {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
