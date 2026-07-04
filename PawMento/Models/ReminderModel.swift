import Foundation
import UserNotifications

enum ReminderFrequency: String, Codable, CaseIterable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
}

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var petId: UUID
    var title: String
    var time: Date
    var frequency: ReminderFrequency
    var categoryId: String // Maps to LogCategory.rawValue
    var isEnabled: Bool = true
    
    // For sorting
    var nextOccurrence: Date {
        let now = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        
        switch frequency {
        case .once:
            // If the time has already passed today, it's effectively past (or we can schedule it for tomorrow)
            // Usually "once" means next 24h. Let's just find the next hour/minute.
            if let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                return nextDate
            }
            return time
        case .daily:
            if let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                return nextDate
            }
            return time
        case .weekly:
            components.weekday = calendar.component(.weekday, from: time)
            if let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
                return nextDate
            }
            return time
        }
    }
    
    /// Whether a one-time reminder's scheduled fire time has already passed (R7 guard).
    var isPastOnceFireTime: Bool {
        guard frequency == .once else { return false }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: time)
        guard let fireDate = calendar.date(from: components) else { return false }
        return fireDate <= Date()
    }
}
