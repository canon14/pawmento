import XCTest
@testable import PawMento

final class TrendDetectorTests: XCTestCase {
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }
    
    private var referenceDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12))!
    }
    
    private func makeSymptom(daysAgo: Int, hour: Int = 12) -> Signal {
        let dayStart = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate)!
        )
        let timestamp = calendar.date(byAdding: .hour, value: hour, to: dayStart)!
        
        return Signal(
            id: UUID(),
            category: .symptom,
            note: nil,
            severity: 3,
            timestamp: timestamp
        )
    }
    
    // MARK: - I7: Partial trailing week normalization
    
    func testConstantRate_partialTrailingWeek_reportsStable() async {
        // One symptom per day for 10 days — last bin is a partial week but same daily rate.
        var signals: [Signal] = []
        for daysAgo in (0..<10).reversed() {
            signals.append(makeSymptom(daysAgo: daysAgo))
        }
        
        let candidates = await TrendDetector.detect(signals)
        
        XCTAssertTrue(
            candidates.isEmpty,
            "Constant symptom rate should not report improving/worsening; got: \(candidates.map(\.internalDescription))"
        )
    }
    
    func testDecliningRate_reportsImproving() async {
        var signals: [Signal] = []
        
        // Week 1: 2 symptoms/day (14 over 7 days)
        for daysAgo in (4..<11).reversed() {
            signals.append(makeSymptom(daysAgo: daysAgo, hour: 8))
            signals.append(makeSymptom(daysAgo: daysAgo, hour: 20))
        }
        
        // Week 2 partial: 1 symptom/day (3 over 3 days)
        for daysAgo in (1..<4).reversed() {
            signals.append(makeSymptom(daysAgo: daysAgo))
        }
        
        let candidates = await TrendDetector.detect(signals)
        
        XCTAssertFalse(candidates.isEmpty, "Genuinely declining rate should surface a trend")
        let desc = candidates.first?.internalDescription ?? ""
        XCTAssertTrue(
            desc.contains("improving"),
            "Declining symptom rate should report improving, got: \(desc)"
        )
    }
}
