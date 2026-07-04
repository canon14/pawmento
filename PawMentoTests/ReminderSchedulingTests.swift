import XCTest
@testable import PawMento

final class ReminderSchedulingTests: XCTestCase {
    
    func testIsPastOnceFireTime_futureOnceReminder_isFalse() {
        let reminder = Reminder(
            petId: UUID(),
            title: "Future",
            time: Date().addingTimeInterval(3600),
            frequency: .once,
            categoryId: LogCategory.meal.rawValue
        )
        XCTAssertFalse(reminder.isPastOnceFireTime)
    }
    
    func testIsPastOnceFireTime_pastOnceReminder_isTrue() {
        let reminder = Reminder(
            petId: UUID(),
            title: "Past",
            time: Date().addingTimeInterval(-3600),
            frequency: .once,
            categoryId: LogCategory.meal.rawValue
        )
        XCTAssertTrue(reminder.isPastOnceFireTime)
    }
    
    func testIsPastOnceFireTime_dailyReminder_isFalse() {
        let reminder = Reminder(
            petId: UUID(),
            title: "Daily",
            time: Date().addingTimeInterval(-3600),
            frequency: .daily,
            categoryId: LogCategory.meal.rawValue
        )
        XCTAssertFalse(reminder.isPastOnceFireTime)
    }
}
