import XCTest
@testable import PawMento

final class InsightCalendarTests: XCTestCase {
    
    func testDistinctDayCount_usesUTCDayBoundaries() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        
        // Two timestamps on adjacent UTC days that often share a local calendar day west of UTC.
        let lateUtcDay = utc.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 23))!
        let earlyUtcNextDay = utc.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 1))!
        
        let local = Calendar.current
        let sameLocalDay =
            local.dateComponents([.year, .month, .day], from: lateUtcDay) ==
            local.dateComponents([.year, .month, .day], from: earlyUtcNextDay)
        
        let count = InsightCalendar.distinctDayCount(for: [lateUtcDay, earlyUtcNextDay])
        
        XCTAssertEqual(count, 2, "UTC bucketing should count adjacent UTC days separately")
        if sameLocalDay {
            XCTAssertNotEqual(
                count,
                1,
                "Device-local bucketing would collapse these into one day"
            )
        }
    }
}
