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
    
    /// Consecutive UTC calendar days with ≥1 log, ending on today (UTC) if logged today,
    /// otherwise ending on yesterday if that day has a log (streak still alive). Otherwise 0.
    /// Same-day multiple logs count once.
    static func consecutiveLoggingStreak(for dates: [Date], relativeTo now: Date = Date()) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let loggedDays: Set<Date> = Set(dates.compactMap { date in
            let components = utc.dateComponents([.year, .month, .day], from: date)
            return utc.date(from: components)
        })
        
        let todayComponents = utc.dateComponents([.year, .month, .day], from: now)
        guard let today = utc.date(from: todayComponents) else { return 0 }
        guard let yesterday = utc.date(byAdding: .day, value: -1, to: today) else { return 0 }
        
        let startDay: Date
        if loggedDays.contains(today) {
            startDay = today
        } else if loggedDays.contains(yesterday) {
            startDay = yesterday
        } else {
            return 0
        }
        
        var streak = 0
        var cursor = startDay
        while loggedDays.contains(cursor) {
            streak += 1
            guard let previous = utc.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }
}
