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
        static let overdueWindowHours: TimeInterval = 48 * 3600  // Only penalize recent overdue
        
        // Fix W1: Data-sufficiency thresholds
        static let insufficientDataThreshold = 3
        static let lowDataThreshold = 7
    }
    
    // Fix W6: routineCategories and activityCategories are DISJOINT (verified):
    //   routine = {meal, potty, sleep, water}
    //   activity = {walk, play, training}
    // If a category is ever added to both sets, logs would be double-counted.
    // Ensure LogCategory.routineCategories and .activityCategories remain disjoint.
    
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
        // Fix W2: Score based on distinct calendar days with ≥1 routine log, not raw count.
        let routineLogs = last14DaysLogs.filter { LogCategory.routineCategories.contains($0.category) }
        let distinctRoutineDays = Self.distinctDayCount(for: routineLogs, upTo: date)
        let routineScore = min(Constants.routineCap, distinctRoutineDays * Constants.routinePointsPerDay)
        
        // 3. Activity Level (Max 20)
        // Fix W2: Same distinct-day approach for activity.
        let activityLogs = last14DaysLogs.filter { LogCategory.activityCategories.contains($0.category) }
        let distinctActivityDays = Self.distinctDayCount(for: activityLogs, upTo: date)
        let activityScore = min(Constants.activityCap, distinctActivityDays * Constants.activityPointsPerDay)
        
        // 4. Medication Compliance (Max 15)
        // Fix W3: Earn points via streakCount; penalize only recently-overdue meds.
        var medCredit = 0
        var overduePenalty = 0
        for med in medications {
            // Earn credit from adherence streaks
            medCredit += min(Constants.maxStreakCreditPerMed, med.streakCount)
            
            // Penalize only if overdue within the recent window (not permanently stale)
            if let due = med.nextDueDate, due < date {
                let overdueAge = date.timeIntervalSince(due)
                if overdueAge <= Constants.overdueWindowHours {
                    overduePenalty += Constants.overduePenaltyPerMed
                }
            }
        }
        let medScore = max(0, min(Constants.medCap, medCredit) - overduePenalty)
        
        let totalScore = Int(symptomScore) + routineScore + activityScore + medScore
        return WellnessResult(score: max(0, min(100, totalScore)), confidence: confidence)
    }
    
    // MARK: - Helpers
    
    /// Count distinct calendar days that have ≥1 log entry.
    private static func distinctDayCount(for logs: [LogEntry], upTo date: Date) -> Int {
        let calendar = Calendar.current
        var uniqueDays = Set<DateComponents>()
        for log in logs {
            let components = calendar.dateComponents([.year, .month, .day], from: log.recordedAt)
            uniqueDays.insert(components)
        }
        return uniqueDays.count
    }
}
