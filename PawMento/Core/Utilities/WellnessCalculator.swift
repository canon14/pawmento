import Foundation

struct WellnessCalculator {
    static func calculateScore(logs: [LogEntry], medications: [Medication], upTo date: Date = Date()) -> Int {
        let last14DaysLogs = logs.filter { $0.recordedAt > date.addingTimeInterval(-14*24*3600) && $0.recordedAt <= date }
        
        // 1. Symptom Burden (Max 40)
        let symptomLogs = last14DaysLogs.filter { $0.category == .symptom }
        var symptomScore = 40
        for s in symptomLogs {
            symptomScore -= (s.severity ?? 1) * 3
        }
        symptomScore = max(0, symptomScore)
        
        // 2. Routine Adherence (Max 25)
        let routineLogs = last14DaysLogs.filter { LogCategory.routineCategories.contains($0.category) }
        let routineScore = min(25, routineLogs.count * 2)
        
        // 3. Activity Level (Max 20)
        let activityLogs = last14DaysLogs.filter { LogCategory.activityCategories.contains($0.category) }
        let activityScore = min(20, activityLogs.count * 3)
        
        // 4. Medication Compliance (Max 15)
        var medScore = 15
        for med in medications {
            if let due = med.nextDueDate, due < date {
                medScore -= 5 // Penalty for overdue
            }
        }
        medScore = max(0, medScore)
        
        let score = symptomScore + routineScore + activityScore + medScore
        return max(0, min(100, score))
    }
}
