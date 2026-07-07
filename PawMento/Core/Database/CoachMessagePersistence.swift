import Foundation
import Supabase

enum CoachMessagePersistence {
    /// When set (tests), redirects inserts instead of Supabase.
    static var insertHandler: ((ChatMessageDTO) async throws -> Void)?
    
    @MainActor
    static func insert(_ message: ChatMessage, ownerId: UUID) async {
        let dto = message.toDTO(ownerId: ownerId)
        do {
            if let insertHandler {
                try await insertHandler(dto)
            } else {
                try await SupabaseManager.shared.client
                    .from("chat_messages")
                    .insert(dto)
                    .execute()
            }
        } catch {
            print("Failed to persist chat message (\(dto.role)): \(error)")
        }
    }
}
