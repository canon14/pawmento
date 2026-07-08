import Foundation

// MARK: - Wellness Result

/// The output of the wellness calculator, including a confidence level
/// that communicates data maturity to the UI.
struct WellnessResult {
    let score: Int // 0–100
    let confidence: DataConfidence
    
    enum DataConfidence {
        /// < 3 logs in window — score is unreliable, UI should show "Gathering data"
        case insufficient
        /// 3–6 logs — score is directional but noisy
        case low
        /// 7+ logs — score is meaningful
        case sufficient
    }
}

// MARK: - Wellness Calculator

struct WellnessCalculator {
    
    // Fix W7: Named constants — all weights, caps, and thresholds in one place.
    private enum Constants {
        // Window
        static let windowDays: TimeInterval = 14 * 24 * 3600 // Fix W5: 14-day window
        
        // Component caps (total = 100)
        static let symptomCap = 40
        static let routineCap = 25
        static let activityCap = 20
        static let medCap = 15
        static let maxScoreWithoutMedications = symptomCap + routineCap + activityCap // 85
        
        // Fix W4: Severity is 1–5 (confirmed via SeveritySliderView).
        // Max deduction per symptom log = 8 points. Normalized: (severity/5) * 8.
        static let maxSeverity: Double = 5.0
        static let maxPenaltyPerSymptom: Double = 8.0
        
        // Fix W2: Points per distinct calendar day with ≥1 log.
        // Routine: 2 pts/day × 13 days ≈ 26 → capped at 25.
        // Activity: 2 pts/day × 10 days ≈ 20 → capped at 20.
        static let routinePointsPerDay = 2
        static let activityPointsPerDay = 2
        
        // Fix W3: Medication compliance
        static let maxStreakCreditPerMed = 5     // Up to 5 pts earned per med via streak
        static let overduePenaltyPerMed = 3      // Deducted per overdue med
        static let overdueEscalationHours: TimeInterval = 48 * 3600  // Extra penalty beyond this age
        /// Newly added meds get a grace window aligned with the wellness window.
        /// During grace, on-time meds do not cap the score at 85 (streak component neutralized).
        /// After grace, med credit requires real streak adherence.
        static let newMedGracePeriod = windowDays
        
        // Fix W1: Data-sufficiency thresholds
        static let insufficientDataThreshold = 3
        static let lowDataThreshold = 7
    }
    
    // W6: Routine and activity buckets are disjoint by construction (see LogCategory.wellnessScoringBucket).
    
    static func calculateScore(logs: [LogEntry], medications: [Medication], upTo date: Date = Date()) -> WellnessResult {
        let windowStart = date.addingTimeInterval(-Constants.windowDays)
        let last14DaysLogs = logs.filter { $0.recordedAt > windowStart && $0.recordedAt <= date }
        
        // Fix W1: Data-sufficiency gate
        let confidence: WellnessResult.DataConfidence
        if last14DaysLogs.count < Constants.insufficientDataThreshold {
            confidence = .insufficient
        } else if last14DaysLogs.count < Constants.lowDataThreshold {
            confidence = .low
        } else {
            confidence = .sufficient
        }
        
        // If insufficient data, return early with score 0 — the caller should not display a numeric score.
        if confidence == .insufficient {
            return WellnessResult(score: 0, confidence: .insufficient)
        }
        
        // 1. Symptom Burden (Max 40)
        // Fix W4: Severity range is 1–5. nil severity = 0 deduction (unknown ≠ mild).
        // Normalized penalty: (severity / 5) * maxPenaltyPerSymptom.
        let symptomLogs = last14DaysLogs.filter { $0.category == .symptom }
        var symptomScore = Double(Constants.symptomCap)
        for s in symptomLogs {
            if let severity = s.severity {
                let normalizedPenalty = (Double(severity) / Constants.maxSeverity) * Constants.maxPenaltyPerSymptom
                symptomScore -= normalizedPenalty
            }
            // nil severity: no deduction (unknown symptom, not auto-penalized)
        }
        symptomScore = max(0, symptomScore)
        
        // 2. Routine Adherence (Max 25)
        // Fix W2: Score based on distinct UTC calendar days with ≥1 routine log, not raw count.
        let routineLogs = last14DaysLogs.filter { $0.category.wellnessScoringBucket == .routine }
        let distinctRoutineDays = Self.distinctDayCount(for: routineLogs)
        let routineScore = min(Constants.routineCap, distinctRoutineDays * Constants.routinePointsPerDay)
        
        // 3. Activity Level (Max 20)
        // Fix W2: Same distinct-day approach for activity.
        let activityLogs = last14DaysLogs.filter { $0.category.wellnessScoringBucket == .activity }
        let distinctActivityDays = Self.distinctDayCount(for: activityLogs)
        let activityScore = min(Constants.activityCap, distinctActivityDays * Constants.activityPointsPerDay)
        
        // 4. Medication Compliance (Max 15) — only applies when the pet has medications
        let hasMedications = !medications.isEmpty
        var medScore = 0
        let allMedsInGrace: Bool
        let anyOverdue: Bool
        if hasMedications {
            allMedsInGrace = medications.allSatisfy { isInGracePeriod($0, upTo: date) }
            anyOverdue = medications.contains { isOverdue($0, upTo: date) }
            
            var medCredit = 0
            var overduePenalty = 0
            for med in medications {
                medCredit += min(Constants.maxStreakCreditPerMed, med.streakCount)
                overduePenalty += overduePenalty(for: med, upTo: date)
            }
            medScore = max(0, min(Constants.medCap, medCredit) - overduePenalty)
        } else {
            allMedsInGrace = false
            anyOverdue = false
        }
        
        let baseScore = Int(symptomScore.rounded()) + routineScore + activityScore
        
        // W1: Pets with no medications renormalize the 85-point base to 100.
        // W16: During new-med grace (all meds < 14 days old, none overdue), neutralize
        // the streak component so perfect adherence can still reach 100.
        let totalScore: Int
        if hasMedications && allMedsInGrace && !anyOverdue {
            totalScore = Int(
                (Double(baseScore) * 100.0 / Double(Constants.maxScoreWithoutMedications)).rounded()
            )
        } else if hasMedications {
            totalScore = baseScore + medScore
        } else {
            totalScore = Int(
                (Double(baseScore) * 100.0 / Double(Constants.maxScoreWithoutMedications)).rounded()
            )
        }
        
        return WellnessResult(score: max(0, min(100, totalScore)), confidence: confidence)
    }
    
    // MARK: - Helpers
    
    private static func isInGracePeriod(_ med: Medication, upTo date: Date) -> Bool {
        date.timeIntervalSince(med.createdAt) <= Constants.newMedGracePeriod
    }
    
    private static func isOverdue(_ med: Medication, upTo date: Date) -> Bool {
        guard let due = med.nextDueDate else { return false }
        return due < date
    }
    
    private static func overduePenalty(for med: Medication, upTo date: Date) -> Int {
        guard let due = med.nextDueDate, due < date else { return 0 }
        let overdueAge = date.timeIntervalSince(due)
        var penalty = Constants.overduePenaltyPerMed
        if overdueAge > Constants.overdueEscalationHours {
            penalty += Constants.overduePenaltyPerMed
        }
        return penalty
    }
    
    /// Count distinct UTC calendar days that have ≥1 log entry (aligned with InsightEngine detectors).
    private static func distinctDayCount(for logs: [LogEntry]) -> Int {
        InsightCalendar.distinctDayCount(for: logs.map(\.recordedAt))
    }
}
