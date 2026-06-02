import Foundation
import Supabase

struct LogDTO: Codable, Identifiable {
    let id: UUID
    let pet_id: UUID
    let log_type: String
    let title: String
    let description: String?
    let timestamp: Date
    let created_by: UUID
    
    // We map the photo URL into `title` temporarily if we want, or add `photo_url` to DB.
    // Wait, `logs` table in `schema.sql` doesn't have `photo_url`! 
    // We should either add `photo_url` to `logs` table in schema.sql OR store it in description.
    // For now, let's assume we can add `photo_url` to `logs` table.
    let photo_url: String?
    
    func toLogEntry() -> LogEntry {
        let category = LogCategory(rawValue: log_type) ?? .other
        
        return LogEntry(
            id: id,
            petId: pet_id,
            category: category,
            severity: nil, // If we parse title/description we could infer this
            note: description,
            photoLocalURL: photo_url.flatMap { URL(string: $0) },
            photoImage: nil,
            createdAt: timestamp,
            recordedAt: timestamp,
            syncedAt: Date()
        )
    }
}

extension LogEntry {
    func toDTO(userId: UUID) -> LogDTO {
        return LogDTO(
            id: id,
            pet_id: petId,
            log_type: category.rawValue,
            title: "\(category.rawValue) Log",
            description: note,
            timestamp: recordedAt,
            created_by: userId,
            photo_url: photoLocalURL?.absoluteString
        )
    }
}
