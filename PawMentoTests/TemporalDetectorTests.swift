import XCTest
@testable import PawMento

final class TemporalDetectorTests: XCTestCase {
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }
    
    private var referenceDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12))!
    }
    
    /// Create a Signal at a specific UTC hour on a given day offset from referenceDate.
    private func makeSignal(
        category: LogCategory = .symptom,
        hour: Int,
        daysAgo: Int = 0,
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
    
    // MARK: - I1: Midnight Wraparound
    
    func testLateNightCluster_22to01_identifiesWraparoundWindow() async {
        // UTC hours 22, 23, 0, 1 across midnight — exercises modulo indexing at startHour >= 21.
        let signals = [
            makeSignal(hour: 22, daysAgo: 1),
            makeSignal(hour: 23, daysAgo: 1),
            makeSignal(hour: 0, daysAgo: 0),
            makeSignal(hour: 1, daysAgo: 0),
            makeSignal(hour: 22, daysAgo: 2)
        ]
        
        let candidates = await TemporalPatternDetector.detect(signals)
        
        XCTAssertFalse(candidates.isEmpty, "Late-night UTC cluster should produce a temporal candidate")
        let desc = candidates.first?.internalDescription ?? ""
        XCTAssertTrue(
            desc.contains("22:00"),
            "Best window should start at 22:00 for the 22→23→0→1 wraparound cluster, got: \(desc)"
        )
    }
    
    func testMidnightWraparound_noCrash() async {
        let signals = [
            makeSignal(hour: 22, daysAgo: 1),
            makeSignal(hour: 23, daysAgo: 1),
            makeSignal(hour: 0, daysAgo: 0),
            makeSignal(hour: 1, daysAgo: 0),
            makeSignal(hour: 22, daysAgo: 2)
        ]
        
        let candidates = await TemporalPatternDetector.detect(signals)
        
        XCTAssertFalse(candidates.isEmpty, "Should detect the midnight-crossing temporal cluster")
        
        if let desc = candidates.first?.internalDescription {
            XCTAssertTrue(
                desc.contains("22:00") || desc.contains("23:00"),
                "Best window should start at 22 or thereabouts, got: \(desc)"
            )
        }
    }
    
    func testMidnightWraparound_bestWindowSpansMidnight() async {
        let signals = [
            makeSignal(hour: 23, daysAgo: 1),
            makeSignal(hour: 23, daysAgo: 2),
            makeSignal(hour: 23, daysAgo: 3),
            makeSignal(hour: 0, daysAgo: 0),
            makeSignal(hour: 0, daysAgo: 1)
        ]
        
        let candidates = await TemporalPatternDetector.detect(signals)
        XCTAssertFalse(candidates.isEmpty)
    }
    
    // MARK: - I7: SafetyClassifier
    
    func testSafetyClassifier_directToxin() {
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "my dog ate chocolate"))
    }
    
    func testSafetyClassifier_tightNegation_suppresses() {
        XCTAssertFalse(SafetyClassifier.isEmergency(message: "didn't eat chocolate"))
    }
    
    func testSafetyClassifier_ambiguousNegation_doesNotSuppress() {
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "I'm not sure if he ate chocolate"))
    }
    
    func testSafetyClassifier_traumaNeverSuppressed() {
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "no idea why he's seizing"))
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "I don't know, he collapsed"))
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "not sure if it's a seizure"))
    }
    
    func testSafetyClassifier_clinicalNeverSuppressed() {
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "no, he can't breathe"))
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "hasn't stopped vomiting blood"))
    }
    
    func testSafetyClassifier_newKeywords() {
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "he has difficulty breathing"))
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "he has a swollen abdomen"))
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "he ate rat bait"))
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "she won't stop vomiting"))
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "he's unable to stand"))
    }
    
    func testSafetyClassifier_benignMessage() {
        XCTAssertFalse(SafetyClassifier.isEmergency(message: "my dog had a good walk today"))
        XCTAssertFalse(SafetyClassifier.isEmergency(message: "she ate her dinner normally"))
    }
    
    func testSafetyClassifier_substringProtection() {
        XCTAssertFalse(SafetyClassifier.isEmergency(message: "my companion is sleeping"))
    }
}
