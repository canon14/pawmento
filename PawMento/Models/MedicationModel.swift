import Foundation

// MARK: - Medication Model (App Logic)
struct Medication: Identifiable {
    let id: UUID
    let petId: UUID
    var name: String
    var frequency: String
    var nextDueDate: Date?
    var streakCount: Int
    let createdAt: Date
    
    init(id: UUID = UUID(), petId: UUID, name: String, frequency: String, nextDueDate: Date? = nil, streakCount: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.petId = petId
        self.name = name
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.streakCount = streakCount
        self.createdAt = createdAt
    }
}

// MARK: - Medication DTO (Database Mapping)
struct MedicationDTO: Codable, Identifiable {
    let id: UUID
    let pet_id: UUID
    var name: String
    var frequency: String
    var next_due_date: Date?
    var streak_count: Int
    let created_at: Date
    
    func toModel() -> Medication {
        return Medication(
            id: id,
            petId: pet_id,
            name: name,
            frequency: frequency,
            nextDueDate: next_due_date,
            streakCount: streak_count,
            createdAt: created_at
        )
    }
}

extension Medication {
    func toDTO() -> MedicationDTO {
        return MedicationDTO(
            id: id,
            pet_id: petId,
            name: name,
            frequency: frequency,
            next_due_date: nextDueDate,
            streak_count: streakCount,
            created_at: createdAt
        )
    }
}
