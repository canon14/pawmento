import XCTest
@testable import PawMento

final class TemporalDetectorTests: XCTestCase {
    
    private let testPetId = UUID()
    
    /// Create a Signal with a given category at a specific hour on a given day offset.
    private func makeSignal(
        category: LogCategory = .symptom,
        hour: Int,
        daysAgo: Int = 0,
        note: String? = nil,
        severity: Int? = nil
    ) -> Signal {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let today = cal.startOfDay(for: Date())
        let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
        let finalDate = cal.date(byAdding: .hour, value: hour, to: date)!
        
        return Signal(
            id: UUID(),
            category: category,
            note: note,
            severity: severity,
            timestamp: finalDate
        )
    }
    
    // MARK: - I1: Midnight Wraparound
    
    func testMidnightWraparound_noCrash() async {
        // Symptoms at hours 22, 23, 0, 1 — the 4-hour window should wrap around midnight
        let signals = [
            makeSignal(hour: 22),
            makeSignal(hour: 23),
            makeSignal(hour: 0, daysAgo: 0),
            makeSignal(hour: 1, daysAgo: 0),
            // Need at least 5 symptoms to pass the guard
            makeSignal(hour: 22, daysAgo: 1)
        ]
        
        // This should NOT crash — the modulo in the sliding window prevents index-out-of-bounds
        let candidates = await TemporalPatternDetector.detect(signals)
        
        // All 5 symptoms cluster in the 22-02 window → should produce a candidate
        XCTAssertFalse(candidates.isEmpty, "Should detect the midnight-crossing temporal cluster")
        
        // Verify the description mentions the correct window
        if let desc = candidates.first?.internalDescription {
            XCTAssertTrue(
                desc.contains("22:00") || desc.contains("23:00"),
                "Best window should start at 22 or thereabouts, got: \(desc)"
            )
        }
    }
    
    func testMidnightWraparound_bestWindowSpansMidnight() async {
        // 3 symptoms at hour 23, 2 at hour 0 → best 4h window is 23-03 or 22-02
        let signals = [
            makeSignal(hour: 23, daysAgo: 0),
            makeSignal(hour: 23, daysAgo: 1),
            makeSignal(hour: 23, daysAgo: 2),
            makeSignal(hour: 0, daysAgo: 0),
            makeSignal(hour: 0, daysAgo: 1)
        ]
        
        let candidates = await TemporalPatternDetector.detect(signals)
        // 5 symptoms in 2 hours → well above the 50%/2.5x threshold
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
        // "I'm not sure if he ate chocolate" — negation is NOT a tight consumption pattern
        XCTAssertTrue(SafetyClassifier.isEmergency(message: "I'm not sure if he ate chocolate"))
    }
    
    func testSafetyClassifier_traumaNeverSuppressed() {
        // "no idea why he's seizing" — old code would suppress; new code does NOT
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
        // "companion" should NOT match "onion" via substring
        XCTAssertFalse(SafetyClassifier.isEmergency(message: "my companion is sleeping"))
    }
}
