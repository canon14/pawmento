import Foundation
import Supabase

struct LogDTO: Codable, Identifiable {
    let id: UUID
    let pet_id: UUID
    let log_type: String
    let title: String
    let description: String?
    let timestamp: Date      // user-facing event time → LogEntry.recordedAt
    let created_at: Date?    // row-insertion time → LogEntry.createdAt (nullable for legacy rows)
    let created_by: UUID
    
    let photo_url: String?
    let severity: Int?
    
    func toLogEntry() -> LogEntry {
        let category = LogCategory(rawValue: log_type) ?? .other
        
        return LogEntry(
            id: id,
            petId: pet_id,
            category: category,
            severity: severity,
            note: description,
            // Fix 2: photo_url stores a bucket-relative path; resolve to full URL for display.
            photoLocalURL: photo_url.flatMap { StorageManager.shared.publicURL(forPath: $0) },
            photoImage: nil,
            createdAt: created_at ?? timestamp,  // DB-L3: fall back to timestamp for legacy rows
            recordedAt: timestamp,               // user-facing event time
            syncedAt: created_at ?? timestamp
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
            timestamp: recordedAt,     // user-facing event time
            created_at: createdAt,     // row-insertion time (server will also default)
            created_by: userId,
            photo_url: StorageManager.shared.relativeStoragePath(from: photoLocalURL),
            severity: severity
        )
    }
    
    func toUpdateDTO() -> LogUpdateDTO {
        return LogUpdateDTO(
            pet_id: petId,
            log_type: category.rawValue,
            title: "\(category.rawValue) Log",
            description: note,
            timestamp: recordedAt,     // preserve the user-facing event time
            photo_url: StorageManager.shared.relativeStoragePath(from: photoLocalURL),
            severity: severity
        )
    }
}

struct LogUpdateDTO: Codable {
    let pet_id: UUID
    let log_type: String
    let title: String
    let description: String?
    let timestamp: Date
    let photo_url: String?
    let severity: Int?
}
