import XCTest
@testable import PawMento

final class ReminderLogSourceKeyTests: XCTestCase {
    
    func testReminderLogSourceKey_isStableForSameMinute() {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 2
        components.hour = 9
        components.minute = 30
        let date = Calendar.current.date(from: components)!
        
        let key = NotificationManager.reminderLogSourceKey(
            reminderId: "abc-123",
            fireDate: date
        )
        
        XCTAssertEqual(key, "reminder:abc-123_2026_7_2_9_30")
    }
}
