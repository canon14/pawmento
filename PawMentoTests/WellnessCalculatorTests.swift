import XCTest
@testable import PawMento

final class WellnessCalculatorTests: XCTestCase {
    
    private let testPetId = UUID()
    
    // MARK: - Helpers
    
    /// Create a log entry with the given category, severity, and days-ago offset.
    private func makeLog(
        category: LogCategory,
        severity: Int? = nil,
        daysAgo: Double = 0,
        from date: Date = Date()
    ) -> LogEntry {
        LogEntry(
            petId: testPetId,
            category: category,
            severity: severity,
            recordedAt: date.addingTimeInterval(-daysAgo * 24 * 3600)
        )
    }
    
    /// Create a medication with the given streak and optional due date.
    private func makeMed(
        streak: Int = 0,
        nextDueDate: Date? = nil
    ) -> Medication {
        Medication(
            petId: testPetId,
            name: "TestMed",
            frequency: "Daily",
            nextDueDate: nextDueDate,
            streakCount: streak
        )
    }
    
    /// Generate N logs on distinct days for the given category.
    private func makeDistinctDayLogs(
        category: LogCategory,
        count: Int,
        from date: Date = Date()
    ) -> [LogEntry] {
        (0..<count).map { i in
            makeLog(category: category, daysAgo: Double(i), from: date)
        }
    }
    
    // MARK: - W1: Data Sufficiency
    
    func testNoData_insufficientConfidence() {
        let result = WellnessCalculator.calculateScore(logs: [], medications: [])
        XCTAssertEqual(result.confidence, .insufficient)
        XCTAssertEqual(result.score, 0)
    }
    
    func testOneLog_insufficientConfidence() {
        let logs = [makeLog(category: .meal, daysAgo: 1)]
        let result = WellnessCalculator.calculateScore(logs: logs, medications: [])
        XCTAssertEqual(result.confidence, .insufficient)
        XCTAssertEqual(result.score, 0)
    }
    
    func testSparseData_lowConfidence() {
        // 4 logs → should be .low (between 3 and 7)
        let logs = (0..<4).map { i in makeLog(category: .meal, daysAgo: Double(i)) }
        let result = WellnessCalculator.calculateScore(logs: logs, medications: [])
        XCTAssertEqual(result.confidence, .low)
        XCTAssertTrue(result.score > 0, "Score should be computed for .low confidence")
    }
    
    func testSufficientData() {
        // 10 logs → should be .sufficient
        let logs = (0..<10).map { i in makeLog(category: .meal, daysAgo: Double(i)) }
        let result = WellnessCalculator.calculateScore(logs: logs, medications: [])
        XCTAssertEqual(result.confidence, .sufficient)
        XCTAssertTrue(result.score > 0)
    }
    
    // MARK: - W4: Symptom Severity
    
    func testSingleMildSymptom() {
        // Need 3+ logs to pass the data-sufficiency gate
        var logs = makeDistinctDayLogs(category: .meal, count: 5)
        logs.append(makeLog(category: .symptom, severity: 1, daysAgo: 0))
        
        let result = WellnessCalculator.calculateScore(logs: logs, medications: [])
        // Symptom: 40 - (1/5)*8 = 40 - 1.6 = 38.4 → 38 (Int)
        // Routine: 5 distinct days * 2 = 10
        // Activity: 0
        // Meds: 0 (no meds)
        // Total: 38 + 10 + 0 + 0 = 48
        XCTAssertEqual(result.score, 48)
    }
    
    func testManySevereSymptoms_floorAtZero() {
        // 10 severity-5 symptoms should not make the score negative
        var logs = makeDistinctDayLogs(category: .meal, count: 3) // pass data gate
        for i in 0..<10 {
            logs.append(makeLog(category: .symptom, severity: 5, daysAgo: Double(i % 14)))
        }
        
        let result = WellnessCalculator.calculateScore(logs: logs, medications: [])
        // Symptom: 40 - 10*(5/5)*8 = 40 - 80 → clamped to 0
        XCTAssertTrue(result.score >= 0, "Score should never go negative")
    }
    
    func testNilSeverity_noDeduction() {
        var logs = makeDistinctDayLogs(category: .meal, count: 5)
        // Symptom with nil severity — should NOT deduct
        logs.append(makeLog(category: .symptom, severity: nil, daysAgo: 0))
        
        let resultWithNil = WellnessCalculator.calculateScore(logs: logs, medications: [])
        
        // Compare against same logs without the symptom
        let logsNoSymptom = makeDistinctDayLogs(category: .meal, count: 5)
        let resultWithout = WellnessCalculator.calculateScore(logs: logsNoSymptom, medications: [])
        
        XCTAssertEqual(resultWithNil.score, resultWithout.score,
                       "nil severity should not deduct from the symptom score")
    }
    
    // MARK: - W2: Distinct Day Adherence
    
    func testRoutineSaturation_distinctDays() {
        // 14 distinct days of meal logs → should max routine at 25
        let logs = makeDistinctDayLogs(category: .meal, count: 14)
        let result = WellnessCalculator.calculateScore(logs: logs, medications: [])
        // Symptom: 40, Routine: min(25, 14*2) = 25, Activity: 0, Meds: 0
        // Total: 40 + 25 = 65
        XCTAssertEqual(result.score, 65)
    }
    
    func testRoutineSpam_sameDay_onlyCountsOnce() {
        // 20 meal logs all on the same day → only 1 distinct day = 2 points
        // Need 3+ total logs to pass data gate, so this works (20 > 3)
        let now = Date()
        let logs = (0..<20).map { _ in makeLog(category: .meal, daysAgo: 0, from: now) }
        
        let result = WellnessCalculator.calculateScore(logs: logs, medications: [])
        // Symptom: 40, Routine: min(25, 1*2) = 2, Activity: 0, Meds: 0
        // Total: 42
        XCTAssertEqual(result.score, 42)
    }
    
    func testActivitySaturation() {
        // 10 distinct days of walks → should max activity at 20
        let logs = makeDistinctDayLogs(category: .walk, count: 10)
        let result = WellnessCalculator.calculateScore(logs: logs, medications: [])
        // Symptom: 40, Routine: 0, Activity: min(20, 10*2) = 20, Meds: 0
        // Total: 60
        XCTAssertEqual(result.score, 60)
    }
    
    // MARK: - W3: Medication Compliance
    
    func testStreakCredit() {
        let logs = makeDistinctDayLogs(category: .meal, count: 7) // pass data gate
        let meds = [makeMed(streak: 5), makeMed(streak: 3)]
        
        let result = WellnessCalculator.calculateScore(logs: logs, medications: meds)
        // Med credit: min(5,5) + min(5,3) = 5 + 3 = 8, capped at 15 → 8
        // No overdue penalty
        // Symptom: 40, Routine: 7*2 = 14, Activity: 0, Meds: 8
        // Total: 62
        XCTAssertEqual(result.score, 62)
    }
    
    func testOverdueMeds_recentlyOverdue_penalized() {
        let logs = makeDistinctDayLogs(category: .meal, count: 7)
        // Med overdue by 12 hours (within 48h window)
        let meds = [makeMed(streak: 5, nextDueDate: Date().addingTimeInterval(-12 * 3600))]
        
        let result = WellnessCalculator.calculateScore(logs: logs, medications: meds)
        // Med credit: min(5,5) = 5, penalty: 3, net: max(0, 5-3) = 2
        // Symptom: 40, Routine: 14, Activity: 0, Meds: 2
        // Total: 56
        XCTAssertEqual(result.score, 56)
    }
    
    func testOverdueMeds_staleOverdue_noPenalty() {
        let logs = makeDistinctDayLogs(category: .meal, count: 7)
        // Med overdue by 72 hours (outside 48h window) — no penalty, just no streak
        let meds = [makeMed(streak: 0, nextDueDate: Date().addingTimeInterval(-72 * 3600))]
        
        let result = WellnessCalculator.calculateScore(logs: logs, medications: meds)
        // Med credit: 0 (no streak), no penalty (outside window)
        // Symptom: 40, Routine: 14, Activity: 0, Meds: 0
        // Total: 54
        XCTAssertEqual(result.score, 54)
    }
    
    // MARK: - W5: Window Boundary
    
    func testBoundaryTimestamp_excluded() {
        // A log exactly at the 14-day boundary uses strict `>`, so it should be EXCLUDED.
        let now = Date()
        let exactlyAtBoundary = now.addingTimeInterval(-14 * 24 * 3600) // exactly 14 days ago
        let justInside = now.addingTimeInterval(-13.99 * 24 * 3600)     // just inside
        
        // 3 meal logs just inside + 1 exactly at boundary
        var logs = [
            makeLog(category: .meal, daysAgo: 1, from: now),
            makeLog(category: .meal, daysAgo: 2, from: now),
            makeLog(category: .meal, daysAgo: 3, from: now)
        ]
        let boundaryLog = LogEntry(petId: testPetId, category: .meal, recordedAt: exactlyAtBoundary)
        logs.append(boundaryLog)
        
        let resultWith = WellnessCalculator.calculateScore(logs: logs, medications: [], upTo: now)
        
        // Remove boundary log → should give same result (boundary excluded by strict >)
        let resultWithout = WellnessCalculator.calculateScore(
            logs: Array(logs.prefix(3)), medications: [], upTo: now
        )
        
        XCTAssertEqual(resultWith.score, resultWithout.score,
                       "Log exactly at 14-day boundary should be excluded (strict > filter)")
    }
    
    // MARK: - Full Score
    
    func testPerfectScore() {
        // 14 distinct routine days + 10 distinct activity days + 3 meds with max streak + no symptoms
        var logs: [LogEntry] = []
        for i in 0..<14 {
            logs.append(makeLog(category: .meal, daysAgo: Double(i)))
        }
        for i in 0..<10 {
            logs.append(makeLog(category: .walk, daysAgo: Double(i)))
        }
        let meds = [makeMed(streak: 5), makeMed(streak: 5), makeMed(streak: 5)]
        
        let result = WellnessCalculator.calculateScore(logs: logs, medications: meds)
        // Symptom: 40, Routine: 25 (14*2 capped), Activity: 20 (10*2 capped), Meds: 15 (3*5 capped)
        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.confidence, .sufficient)
    }
}
