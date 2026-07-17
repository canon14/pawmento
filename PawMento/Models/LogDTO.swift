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
    
    /// Insert payload omits nil optional keys so PostgREST won't reject rows
    /// when legacy DBs are missing nullable columns (e.g. photo_url).
    func toInsertDTO(userId: UUID) -> LogInsertDTO {
        LogInsertDTO(
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

/// Encodes only present optional fields — avoids schema-cache errors on legacy DBs.
struct LogInsertDTO: Encodable {
    let id: UUID
    let pet_id: UUID
    let log_type: String
    let title: String
    let description: String?
    let timestamp: Date
    let created_at: Date?
    let created_by: UUID
    let photo_url: String?
    let severity: Int?
    let source_key: String?
    
    enum CodingKeys: String, CodingKey {
        case id, pet_id, log_type, title, description, timestamp, created_at, created_by
        case photo_url, severity, source_key
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pet_id, forKey: .pet_id)
        try container.encode(log_type, forKey: .log_type)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(created_at, forKey: .created_at)
        try container.encode(created_by, forKey: .created_by)
        try container.encodeIfPresent(photo_url, forKey: .photo_url)
        try container.encodeIfPresent(severity, forKey: .severity)
        try container.encodeIfPresent(source_key, forKey: .source_key)
    }
}

struct LogUpdateDTO: Encodable {
    let pet_id: UUID
    let log_type: String
    let title: String
    let description: String?
    let timestamp: Date
    let photo_url: String?
    let severity: Int?
    
    enum CodingKeys: String, CodingKey {
        case pet_id, log_type, title, description, timestamp, photo_url, severity
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pet_id, forKey: .pet_id)
        try container.encode(log_type, forKey: .log_type)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(photo_url, forKey: .photo_url)
        try container.encodeIfPresent(severity, forKey: .severity)
    }
}
