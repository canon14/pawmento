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
    
    // For Supabase
    var petId: UUID?
    
    // Convert to dictionary format expected by OpenAI/Anthropic
    func toAPIFormat() -> [String: String] {
        return ["role": role.rawValue, "content": content]
    }
}
