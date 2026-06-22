import Foundation

// MARK: - Medication Model (App Logic)
struct Medication: Identifiable {
    let id: UUID
    let petId: UUID
    var name: String
    var dose: String?
    var form: String?
    var frequency: String
    var nextDueDate: Date?
    var streakCount: Int
    var loggedToday: Bool
    let createdAt: Date
    
    init(id: UUID = UUID(), petId: UUID, name: String, dose: String? = nil, form: String? = nil, frequency: String, nextDueDate: Date? = nil, streakCount: Int = 0, loggedToday: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.petId = petId
        self.name = name
        self.dose = dose
        self.form = form
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.streakCount = streakCount
        self.loggedToday = loggedToday
        self.createdAt = createdAt
    }
}

// MARK: - Medication DTO (Database Mapping)
struct MedicationDTO: Codable, Identifiable {
    let id: UUID
    let pet_id: UUID
    var name: String
    var dose: String?
    var form: String?
    var frequency: String
    var next_due_date: Date?
    var streak_count: Int
    var logged_today: Bool?
    let created_at: Date
    
    func toModel() -> Medication {
        return Medication(
            id: id,
            petId: pet_id,
            name: name,
            dose: dose,
            form: form,
            frequency: frequency,
            nextDueDate: next_due_date,
            streakCount: streak_count,
            loggedToday: logged_today ?? false,
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
            dose: dose,
            form: form,
            frequency: frequency,
            next_due_date: nextDueDate,
            streak_count: streakCount,
            logged_today: loggedToday,
            created_at: createdAt
        )
    }
}
