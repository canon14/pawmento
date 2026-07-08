import XCTest
@testable import PawMento

final class CorrelationDetectorTests: XCTestCase {
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }
    
    private var referenceDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12))!
    }
    
    private func makeSignal(
        category: LogCategory,
        daysAgo: Int,
        hour: Int = 12,
        note: String? = nil,
        severity: Int? = nil
    ) -> Signal {
        let dayStart = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate)!
        )
        let timestamp = calendar.date(byAdding: .hour, value: hour, to: dayStart)!
        
        return Signal(
            id: UUID(),
            category: category,
            note: note,
            severity: severity,
            timestamp: timestamp
        )
    }
    
    // MARK: - I5: Overlap de-duplication
    
    func testDailyTrigger_randomSymptoms_noFalseCorrelation() async {
        var signals: [Signal] = []
        
        // Daily chicken for 30 days (~30 exposures).
        for daysAgo in 0..<30 {
            signals.append(makeSignal(category: .meal, daysAgo: daysAgo, note: "chicken"))
        }
        
        // ~1 in 7 symptom days (deterministic pseudo-random spread).
        for daysAgo in [3, 10, 17, 24, 28] {
            signals.append(makeSignal(category: .symptom, daysAgo: daysAgo, hour: 18, severity: 3))
        }
        
        let candidates = await CorrelationDetector.detect(signals)
        let chickenClaims = candidates.filter { $0.internalDescription.contains("chicken") }
        
        XCTAssertTrue(
            chickenClaims.isEmpty,
            "Daily chicken with sparse random symptoms should not produce a strong correlation; got: \(chickenClaims.map(\.internalDescription))"
        )
    }
    
    func testClusteredTriggerSymptom_detectsCorrelation() async {
        var signals: [Signal] = []
        
        // 8 chicken exposures every 4 days, each followed by a symptom ~18h later.
        for offset in stride(from: 0, through: 28, by: 4) {
            signals.append(makeSignal(category: .meal, daysAgo: 28 - offset, hour: 8, note: "chicken"))
            signals.append(
                makeSignal(category: .symptom, daysAgo: 28 - offset, hour: 20, severity: 4)
            )
        }
        
        let candidates = await CorrelationDetector.detect(signals)
        let chickenClaims = candidates.filter { $0.internalDescription.contains("chicken") }
        
        XCTAssertFalse(chickenClaims.isEmpty, "Clustered trigger→symptom pairs should surface a correlation")
        XCTAssertGreaterThanOrEqual(chickenClaims.first?.evidenceCount ?? 0, 4)
    }
    
    func testUnrelatedTrigger_noCorrelationWhenSymptomsUnlinked() async {
        var signals: [Signal] = []
        
        // Symptoms logged early, before the chicken regimen starts.
        for daysAgo in [26, 27, 28, 29, 30] {
            signals.append(makeSignal(category: .symptom, daysAgo: daysAgo, hour: 8, severity: 3))
        }
        
        // Daily chicken only in the recent window (starts >48h after the early symptoms).
        for daysAgo in 0..<23 {
            signals.append(makeSignal(category: .meal, daysAgo: daysAgo, hour: 20, note: "chicken"))
        }
        
        let candidates = await CorrelationDetector.detect(signals)
        let chickenClaims = candidates.filter { $0.internalDescription.contains("chicken") }
        
        XCTAssertTrue(
            chickenClaims.isEmpty,
            "Symptoms with no qualifying preceding exposure should not inflate hits; got: \(chickenClaims.map(\.internalDescription))"
        )
    }
}
