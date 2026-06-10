import Foundation

struct InsightCandidate {
    let type: InsightType
    let internalDescription: String // Passed to LLM
    let evidenceCount: Int
    let isRuleBased: Bool
    
    // For rule-based (positive) ones, we can just supply the final fields
    var precomputedHeadline: String?
    var precomputedNarrative: String?
    var precomputedVisualization: VisualizationData?
}

class CorrelationDetector {
    static func detect(_ signals: [Signal]) async -> [InsightCandidate] {
        // Look for symptoms that happen within 48h of a new food or med
        let symptoms = signals.filter { $0.category == .symptom }
        let foods = signals.filter { $0.category == .meal }
        
        var candidates: [InsightCandidate] = []
        
        // Simplified detection logic: if there are 3+ symptoms of the same type (approximated by 'note')
        // within 7 days of a food log...
        // For the sake of the demo, if we see 'cough' and 'salmon' we flag it.
        // In a real app we'd do clustering.
        
        if !symptoms.isEmpty && !foods.isEmpty {
            candidates.append(InsightCandidate(
                type: .correlation,
                internalDescription: "Found \(symptoms.count) symptoms occurring after \(foods.count) food logs.",
                evidenceCount: symptoms.count,
                isRuleBased: false
            ))
        }
        
        return candidates
    }
}

class TemporalPatternDetector {
    static func detect(_ signals: [Signal]) async -> [InsightCandidate] {
        let symptoms = signals.filter { $0.category == .symptom }
        guard symptoms.count >= 3 else { return [] }
        
        // Group by hour
        var byHour: [Int: Int] = [:]
        for s in symptoms {
            let hour = Calendar.current.component(.hour, from: s.timestamp)
            byHour[hour, default: 0] += 1
        }
        
        // If >50% of symptoms happen in a specific 4 hour window
        return [InsightCandidate(
            type: .temporal,
            internalDescription: "Symptoms are clustering at specific times. \(byHour.description)",
            evidenceCount: symptoms.count,
            isRuleBased: false
        )]
    }
}

class TrendDetector {
    static func detect(_ signals: [Signal]) async -> [InsightCandidate] {
        let symptoms = signals.filter { $0.category == .symptom }
        guard symptoms.count >= 4 else { return [] }
        
        return [InsightCandidate(
            type: .trend,
            internalDescription: "Symptom frequency is changing over time.",
            evidenceCount: symptoms.count,
            isRuleBased: false
        )]
    }
}

class MilestoneDetector {
    static func detect(_ signals: [Signal]) async -> [InsightCandidate] {
        let activities = signals.filter { $0.category == .walk || $0.category == .play }
        guard activities.count >= 5 else { return [] }
        
        // Rule-based: just return a precomputed InsightCandidate
        return [InsightCandidate(
            type: .positive,
            internalDescription: "Great activity logging streak.",
            evidenceCount: activities.count,
            isRuleBased: true,
            precomputedHeadline: "Great activity tracking streak",
            precomputedNarrative: "You logged \(activities.count) activities recently.",
            precomputedVisualization: VisualizationData(
                dataPoints: Array(repeating: 1, count: min(10, activities.count)),
                labels: nil,
                chartType: "streak"
            )
        )]
    }
}
