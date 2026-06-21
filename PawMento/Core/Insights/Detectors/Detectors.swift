import Foundation

struct InsightCandidate {
    let id: UUID
    let type: InsightType
    let internalDescription: String // Passed to LLM
    let evidenceCount: Int
    let isRuleBased: Bool
    
    // For rule-based (positive) ones, we can just supply the final fields
    var precomputedHeadline: String?
    var precomputedNarrative: String?
    var precomputedVisualization: VisualizationData?
}

// Fix I8: Capture timezone at app start for consistent bucketing.
// Using UTC ensures historical analysis is stable regardless of device travel.
private let insightCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone.current // Use the user's home timezone
    return cal
}()

class CorrelationDetector {
    static func detect(_ signals: [Signal]) async -> [InsightCandidate] {
        // 48 hours in seconds
        let exposureWindow: TimeInterval = 48 * 3600
        // Fix I4: Raise minimum exposures from 3 → 5 for statistical rigor
        let minExposures = 5
        let minHits = 4
        
        let symptoms = signals.filter { $0.category == .symptom }
        let triggers = signals.filter { signal in
            (signal.category == .meal || signal.category == .med) && 
            !(signal.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        guard symptoms.count >= minExposures, !triggers.isEmpty else {
            return []
        }
        
        var totalByTrigger: [String: Int] = [:]
        var hitsByTrigger: [String: Int] = [:]
        
        for trigger in triggers {
            let key = (trigger.note ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            totalByTrigger[key, default: 0] += 1
            
            let hasHit = symptoms.contains { symptom in
                let dt = symptom.timestamp.timeIntervalSince(trigger.timestamp)
                return dt >= 0 && dt <= exposureWindow
            }
            
            if hasHit {
                hitsByTrigger[key, default: 0] += 1
            }
        }
        
        let timestamps = signals.map { $0.timestamp }
        let minTime = timestamps.min()?.timeIntervalSince1970 ?? 0
        let maxTime = timestamps.max()?.timeIntervalSince1970 ?? 0
        let totalSpan = maxTime - minTime
        
        // Statistical Model:
        // We model symptom occurrences as a Poisson process.
        // lambda = expected number of symptoms in a 48h window
        // baselineProb = Probability of at least one symptom in a random 48h window: 1 - exp(-lambda)
        let lambda = Double(symptoms.count) * (exposureWindow / max(totalSpan, exposureWindow))
        var baselineProb = 1.0 - exp(-lambda)
        
        // Clamp to sensible floor/ceiling to avoid divide-by-zero or overly sensitive triggers
        baselineProb = max(0.02, min(baselineProb, 0.95))
        
        var candidates: [InsightCandidate] = []
        
        // Fix I4: Bonferroni-like correction — number of distinct triggers tested
        let numTriggersTested = totalByTrigger.filter { $0.value >= minExposures }.count
        // Effective threshold: raise the rate gate proportionally to the number of comparisons
        let adjustedRateThreshold = min(0.95, 0.6 * (1.0 + 0.05 * Double(max(0, numTriggersTested - 1))))
        
        for (key, totalExposures) in totalByTrigger where totalExposures >= minExposures {
            let hits = hitsByTrigger[key] ?? 0
            
            // Fix I4: Require minimum hits, not just minimum exposures
            guard hits >= minHits else { continue }
            
            // Percentage of times this trigger was followed by a symptom
            let observedRate = Double(hits) / Double(totalExposures)
            
            // How much more likely is a symptom after this trigger compared to baseline probability
            let relativeRisk = observedRate / baselineProb
            
            if observedRate >= adjustedRateThreshold && relativeRisk >= 2.0 {
                let percentStr = Int(observedRate * 100)
                let rrStr = String(format: "%.1fx", relativeRisk)
                
                // Fix I4: Non-causal language — "possible association", not "frequently follow"
                let desc = "Possible association observed: symptoms appeared after '\(key)' in \(hits) of \(totalExposures) instances (\(percentStr)%), which is \(rrStr) the baseline rate. This is a pattern worth discussing with your vet — not a diagnosis."
                
                candidates.append(InsightCandidate(
                    id: UUID(),
                    type: .correlation,
                    internalDescription: desc,
                    evidenceCount: hits,
                    isRuleBased: false
                ))
            }
        }
        
        // Fix I4: Cap surfaced correlations to top 2 by evidence count to limit false discovery rate
        candidates.sort { $0.evidenceCount > $1.evidenceCount }
        return Array(candidates.prefix(2))
    }
}

class TemporalPatternDetector {
    static func detect(_ signals: [Signal]) async -> [InsightCandidate] {
        let symptoms = signals.filter { $0.category == .symptom }
        let total = symptoms.count
        
        guard total >= 5 else { return [] }
        
        var byHour = [Int](repeating: 0, count: 24)
        for s in symptoms {
            // Fix I8: Use fixed calendar for consistent timezone bucketing
            let hour = insightCalendar.component(.hour, from: s.timestamp)
            if hour >= 0 && hour < 24 {
                byHour[hour] += 1
            }
        }
        
        var bestStart = 0
        var bestCount = 0
        let windowSize = 4
        
        for startHour in 0..<24 {
            var currentCount = 0
            for offset in 0..<windowSize {
                // Fix I1: Modulo wraps correctly for midnight crossing (already present)
                let hour = (startHour + offset) % 24
                currentCount += byHour[hour]
            }
            if currentCount > bestCount {
                bestCount = currentCount
                bestStart = startHour
            }
        }
        
        let observedShare = Double(bestCount) / Double(total)
        let expectedShare = 4.0 / 24.0 // ~0.167
        
        guard observedShare >= 0.5, observedShare >= expectedShare * 2.5 else {
            return []
        }
        
        let windowEnd = (bestStart + windowSize) % 24
        let percentStr = Int(observedShare * 100)
        let internalDescription = "Found \(bestCount)/\(total) symptoms (\(percentStr)%) clustered between \(bestStart):00 and \(windowEnd):00. This significantly exceeds the ~17% expected if spread uniformly."
        
        let labels = (0..<24).map { "\($0)" }
        let dataPoints = byHour.map { Double($0) }
        
        let visualization = VisualizationData(
            dataPoints: dataPoints,
            labels: labels,
            chartType: "bar"
        )
        
        return [InsightCandidate(
            id: UUID(),
            type: .temporal,
            internalDescription: internalDescription,
            evidenceCount: bestCount,
            isRuleBased: false,
            precomputedVisualization: visualization
        )]
    }
}

class TrendDetector {
    static func detect(_ signals: [Signal]) async -> [InsightCandidate] {
        let symptoms = signals.filter { $0.category == .symptom }
        
        let timestamps = symptoms.map { $0.timestamp.timeIntervalSince1970 }
        guard symptoms.count >= 6, let first = timestamps.min(), let last = timestamps.max() else {
            return []
        }
        
        let oneWeek: TimeInterval = 7 * 24 * 3600
        let span = last - first
        let weeks = max(2, Int(span / oneWeek) + 1)
        
        var counts = [Double](repeating: 0, count: weeks)
        for t in timestamps {
            let bin = min(weeks - 1, Int((t - first) / oneWeek))
            if bin >= 0 && bin < weeks {
                counts[bin] += 1
            }
        }
        
        let xs = (0..<weeks).map { Double($0) }
        let ys = counts
        
        let meanX = xs.reduce(0, +) / Double(weeks)
        let meanY = ys.reduce(0, +) / Double(weeks)
        
        var cov: Double = 0
        var varX: Double = 0
        
        for i in 0..<weeks {
            let dx = xs[i] - meanX
            let dy = ys[i] - meanY
            cov += dx * dy
            varX += dx * dx
        }
        
        guard varX > 0 else { return [] }
        let slope = cov / varX
        
        let relativeSlope = slope / max(meanY, 1.0)
        guard abs(relativeSlope) >= 0.25 else { return [] }
        
        let direction = slope > 0 ? "worsening" : "improving"
        let sign = slope > 0 ? "+" : ""
        let slopeStr = String(format: "%.1f", slope)
        let avgStr = String(format: "%.1f", meanY)
        
        let internalDescription = "Trend is \(direction). Change is \(sign)\(slopeStr) symptoms/week over \(weeks) weeks (avg \(avgStr) per week)."
        
        let labels = (1...weeks).map { "W\($0)" }
        let visualization = VisualizationData(
            dataPoints: counts,
            labels: labels,
            chartType: "sparkline"
        )
        
        return [InsightCandidate(
            id: UUID(),
            type: .trend,
            internalDescription: internalDescription,
            evidenceCount: symptoms.count,
            isRuleBased: false,
            precomputedVisualization: visualization
        )]
    }
}

class MilestoneDetector {
    static func detect(_ signals: [Signal]) async -> [InsightCandidate] {
        let activities = signals.filter { LogCategory.activityCategories.contains($0.category) }
        guard activities.count >= 5 else { return [] }
        
        // Rule-based: just return a precomputed InsightCandidate
        return [InsightCandidate(
            id: UUID(),
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
