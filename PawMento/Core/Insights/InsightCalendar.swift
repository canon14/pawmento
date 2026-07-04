import Foundation

/// UTC Gregorian calendar for deterministic day bucketing across wellness + insights.
/// Fix I8 + W2: Historical analysis stays stable regardless of device travel or timezone changes.
enum InsightCalendar {
    static let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()
    
    /// Count distinct UTC calendar days represented in the given timestamps.
    static func distinctDayCount(for dates: [Date]) -> Int {
        var uniqueDays = Set<DateComponents>()
        for date in dates {
            let components = utc.dateComponents([.year, .month, .day], from: date)
            uniqueDays.insert(components)
        }
        return uniqueDays.count
    }
}
