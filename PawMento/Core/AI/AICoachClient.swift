import Foundation

enum AIProvider {
    case openai
    case anthropic
}

class AICoachClient {
    static let shared = AICoachClient()
    
    // Defaulting to Anthropic Haiku for cost efficiency as per spec
    var provider: AIProvider = .anthropic
    
    private var anthropicApiKey: String = Secrets.anthropicApiKey
    private var openaiApiKey: String = Secrets.openaiApiKey
    
    private init() {}
    
    /// Generates advice from the AI Coach using SSE streaming
    func streamAdvice(messages: [[String: String]]) -> AsyncThrowingStream<String, Error> {
        switch provider {
        case .anthropic:
            return streamAnthropic(messages: messages)
        case .openai:
            return streamOpenAI(messages: messages)
        }
    }
    
    // MARK: - OpenAI Streaming
    private func streamOpenAI(messages: [[String: String]]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(openaiApiKey)", forHTTPHeaderField: "Authorization")
                    
                    var payloadMessages = [["role": "system", "content": AICoachPrompt.systemPrompt]]
                    payloadMessages.append(contentsOf: messages)
                    
                    let body: [String: Any] = [
                        "model": "gpt-4o-mini", // Cost management as per spec
                        "messages": payloadMessages,
                        "stream": true
                    ]
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (result, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: URLError(.badServerResponse))
                        return
                    }
                    
                    for try await line in result.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = line.dropFirst(6)
                        if jsonString == "[DONE]" { break }
                        
                        guard let data = jsonString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let firstChoice = choices.first,
                              let delta = firstChoice["delta"] as? [String: Any],
                              let content = delta["content"] as? String else { continue }
                        
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Anthropic Streaming
    private func streamAnthropic(messages: [[String: String]]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = URL(string: "https://api.anthropic.com/v1/messages")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    request.setValue(anthropicApiKey, forHTTPHeaderField: "x-api-key")
                    
                    let body: [String: Any] = [
                        "model": "claude-3-haiku-20240307", // Cost management
                        "max_tokens": 1024,
                        "system": AICoachPrompt.systemPrompt,
                        "messages": messages,
                        "stream": true
                    ]
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (result, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: URLError(.badServerResponse))
                        return
                    }
                    
                    for try await line in result.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = line.dropFirst(6)
                        guard let data = jsonString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let type = json["type"] as? String else { continue }
                        
                        if type == "content_block_delta",
                           let delta = json["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        } else if type == "message_stop" {
                            break
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
