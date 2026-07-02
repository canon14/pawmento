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
    let source_key: String?
    
    func toLogEntry() -> LogEntry {
        let category = LogCategory.resolvingStoredLogType(log_type, context: "LogDTO.toLogEntry")
        
        return LogEntry(
            id: id,
            petId: pet_id,
            category: category,
            severity: severity,
            note: description,
            sourceKey: source_key,
            photoLocalURL: photo_url.flatMap { StorageManager.shared.publicURL(forPath: $0) },
            photoImage: nil,
            createdAt: created_at ?? timestamp,
            recordedAt: timestamp,
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
            timestamp: recordedAt,
            created_at: createdAt,
            created_by: userId,
            photo_url: StorageManager.shared.relativeStoragePath(from: photoLocalURL),
            severity: severity,
            source_key: sourceKey
        )
    }
    
    func toUpdateDTO() -> LogUpdateDTO {
        return LogUpdateDTO(
            pet_id: petId,
            log_type: category.rawValue,
            title: "\(category.rawValue) Log",
            description: note,
            timestamp: recordedAt,
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
