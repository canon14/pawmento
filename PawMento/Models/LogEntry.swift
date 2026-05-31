import Foundation

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let petId: UUID
    var category: LogCategory
    var severity: Int? // 1-5, conditionally populated for .symptom
    var note: String? // max 280 chars
    var photoLocalURL: URL?
    let createdAt: Date // server time
    let recordedAt: Date // local time
    var syncedAt: Date?
    
    init(id: UUID = UUID(), 
         petId: UUID, 
         category: LogCategory, 
         severity: Int? = nil, 
         note: String? = nil, 
         photoLocalURL: URL? = nil, 
         createdAt: Date = Date(), 
         recordedAt: Date = Date(), 
         syncedAt: Date? = nil) {
        self.id = id
        self.petId = petId
        self.category = category
        self.severity = severity
        self.note = note
        self.photoLocalURL = photoLocalURL
        self.createdAt = createdAt
        self.recordedAt = recordedAt
        self.syncedAt = syncedAt
    }
}
