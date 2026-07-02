import Foundation

// MARK: - Medication Frequency

enum MedicationFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case twiceDaily = "Twice daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case asNeeded = "As needed"
    
    var displayName: String { rawValue }
}

enum MedicationForm: String, Codable, CaseIterable {
    case pill = "Pill"
    case liquid = "Liquid"
    case injectable = "Injectable"
    case topical = "Topical"
    case other = "Other"
    
    var displayName: String { rawValue }
}

// MARK: - Medication Model (App Logic)

struct Medication: Identifiable, Equatable {
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
    
    init(
        id: UUID = UUID(),
        petId: UUID,
        name: String,
        dose: String? = nil,
        form: String? = nil,
        frequency: String,
        nextDueDate: Date? = nil,
        streakCount: Int = 0,
        loggedToday: Bool = false,
        createdAt: Date = Date()
    ) {
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
    
    var medicationFrequency: MedicationFrequency {
        MedicationFrequency(rawValue: frequency) ?? .daily
    }
    
    /// Advances `nextDueDate` after a dose is logged, based on frequency.
    static func nextDueDate(after date: Date, frequency: String, previousDue: Date?) -> Date? {
        let calendar = Calendar.current
        let anchor = previousDue ?? date
        
        switch MedicationFrequency(rawValue: frequency) ?? .daily {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: anchor)
        case .twiceDaily:
            return calendar.date(byAdding: .hour, value: 12, to: anchor)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: anchor)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: anchor)
        case .asNeeded:
            return nil
        }
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
    var logged_today: Bool
    let created_at: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case pet_id
        case name
        case dose
        case form
        case frequency
        case next_due_date
        case streak_count
        case logged_today
        case created_at
    }
    
    func toModel() -> Medication {
        Medication(
            id: id,
            petId: pet_id,
            name: name,
            dose: dose,
            form: form,
            frequency: frequency,
            nextDueDate: next_due_date,
            streakCount: streak_count,
            loggedToday: logged_today,
            createdAt: created_at
        )
    }
}

extension Medication {
    func toDTO() -> MedicationDTO {
        MedicationDTO(
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
