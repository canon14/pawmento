import Foundation

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let role: ChatRole
    var content: String
    var timestamp: Date = Date()
    var isEmergency: Bool = false
    /// Local-only: assistant bubble can be tapped to retry the preceding user send.
    var isRetryable: Bool = false
    
    // For Supabase
    var petId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp, isEmergency, petId
    }
    
    // Convert to dictionary format expected by OpenAI/Anthropic
    func toAPIFormat() -> [String: String] {
        return ["role": role.rawValue, "content": content]
    }
}
