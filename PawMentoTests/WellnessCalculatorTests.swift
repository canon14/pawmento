import XCTest
@testable import PawMento

final class WellnessCalculatorTests: XCTestCase {
    
    func testSymptomSeverityAffectsScore() {
        // Base symptom score is 40.
        // Penalty = severity * 3.
        
        // 1. Test with Severity 1
        let logSeverity1 = LogEntry(
            id: UUID(),
            petId: UUID(),
            category: .symptom,
            severity: 1, // Penalty should be 1 * 3 = 3
            note: "Mild cough",
            recordedAt: Date()
        )
        let scoreWithSeverity1 = WellnessCalculator.calculateScore(logs: [logSeverity1], medications: [])
        
        // Expected score calculation:
        // Symptom: 40 - 3 = 37
        // Routine: 0
        // Activity: 0
        // Meds: 15
        // Total = 52
        XCTAssertEqual(scoreWithSeverity1, 52, "Score with severity 1 should subtract 3 from symptom bucket, resulting in 52")
        
        // 2. Test with Severity 5
        let logSeverity5 = LogEntry(
            id: UUID(),
            petId: UUID(),
            category: .symptom,
            severity: 5, // Penalty should be 5 * 3 = 15
            note: "Severe vomiting",
            recordedAt: Date()
        )
        let scoreWithSeverity5 = WellnessCalculator.calculateScore(logs: [logSeverity5], medications: [])
        
        // Expected score calculation:
        // Symptom: 40 - 15 = 25
        // Routine: 0
        // Activity: 0
        // Meds: 15
        // Total = 40
        XCTAssertEqual(scoreWithSeverity5, 40, "Score with severity 5 should subtract 15 from symptom bucket, resulting in 40")
        
        // 3. Compare them explicitly
        XCTAssertTrue(scoreWithSeverity1 > scoreWithSeverity5, "Higher severity should result in a lower overall wellness score")
    }
}
