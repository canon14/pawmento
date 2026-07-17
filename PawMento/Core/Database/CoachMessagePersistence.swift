import Foundation
import Supabase

enum CoachMessagePersistence {
    /// When set (tests), redirects inserts instead of Supabase.
    static var insertHandler: ((ChatMessageDTO) async throws -> Void)?
    /// When set (tests), redirects deletes instead of Supabase.
    static var deleteHandler: ((UUID, UUID) async throws -> Void)?
    
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
    
    @MainActor
    static func delete(id: UUID, ownerId: UUID) async {
        do {
            if let deleteHandler {
                try await deleteHandler(id, ownerId)
            } else {
                try await SupabaseManager.shared.client
                    .from("chat_messages")
                    .delete()
                    .eq("id", value: id.uuidString)
                    .eq("owner_id", value: ownerId.uuidString)
                    .execute()
            }
        } catch {
            print("Failed to delete chat message (\(id)): \(error)")
        }
    }
}
