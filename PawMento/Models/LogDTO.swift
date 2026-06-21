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
            photoLocalURL: photo_url.flatMap { URL(string: $0) },
            photoImage: nil,
            createdAt: timestamp,
            recordedAt: timestamp,
            syncedAt: timestamp
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
            photo_url: photoLocalURL?.absoluteString,
            severity: severity
        )
    }
    
    func toUpdateDTO() -> LogUpdateDTO {
        return LogUpdateDTO(
            pet_id: petId,
            log_type: category.rawValue,
            title: "\(category.rawValue) Log",
            description: note,
            timestamp: recordedAt,
            photo_url: photoLocalURL?.absoluteString,
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
