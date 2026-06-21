import Foundation

struct ReminderDTO: Codable {
    let id: UUID
    let pet_id: UUID
    let title: String
    let reminder_time: Date
    let frequency: String
    let category_id: String
    let is_enabled: Bool
    
    func toReminder() -> Reminder {
        return Reminder(
            id: id,
            petId: pet_id,
            title: title,
            time: reminder_time,
            frequency: ReminderFrequency(rawValue: frequency) ?? .once,
            categoryId: category_id,
            isEnabled: is_enabled
        )
    }
}

extension Reminder {
    func toDTO() -> ReminderDTO {
        return ReminderDTO(
            id: id,
            pet_id: petId,
            title: title,
            reminder_time: time,
            frequency: frequency.rawValue,
            category_id: categoryId,
            is_enabled: isEnabled
        )
    }
}
