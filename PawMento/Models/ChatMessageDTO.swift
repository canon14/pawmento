import Foundation
import Supabase

struct ChatMessageDTO: Codable, Identifiable {
    let id: UUID
    let owner_id: UUID
    let pet_id: UUID?
    let role: String
    let content: String
    let is_emergency: Bool
    let created_at: Date
    
    func toMessage() -> ChatMessage {
        let chatRole: ChatRole
        switch role.lowercased() {
        case "user": chatRole = .user
        case "assistant": chatRole = .assistant
        case "system": chatRole = .system
        default: chatRole = .user
        }
        
        return ChatMessage(
            id: id,
            role: chatRole,
            content: content,
            timestamp: created_at,
            isEmergency: is_emergency,
            petId: pet_id
        )
    }
}

extension ChatMessage {
    func toDTO(ownerId: UUID) -> ChatMessageDTO {
        return ChatMessageDTO(
            id: id,
            owner_id: ownerId,
            pet_id: petId,
            role: role.rawValue,
            content: content,
            is_emergency: isEmergency,
            created_at: timestamp
        )
    }
}
