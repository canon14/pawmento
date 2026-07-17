import Foundation

/// Deterministic insight surfacing order for early-stage users.
/// Sort key: (typeRank, tier.priority, -confidence).
enum InsightOrdering {
    /// Lower rank surfaces first: milestone/positive → temporal → trend → correlation.
    nonisolated static func typeRank(for type: InsightType) -> Int {
        switch type {
        case .positive: return 0
        case .temporal: return 1
        case .trend: return 2
        case .correlation: return 3
        }
    }
    
    nonisolated static func sortKey(for insight: Insight) -> (Int, Int, Double) {
        (typeRank(for: insight.type), insight.tier.priority, -insight.confidence)
    }
    
    /// Returns true when `lhs` should appear before `rhs`.
    nonisolated static func sortsBefore(_ lhs: Insight, _ rhs: Insight) -> Bool {
        sortKey(for: lhs) < sortKey(for: rhs)
    }
    
    nonisolated static func sorted(_ insights: [Insight]) -> [Insight] {
        insights.sorted { sortsBefore($0, $1) }
    }
    
    nonisolated static func bestInsight(from insights: [Insight]) -> Insight? {
        insights.min(by: sortsBefore)
    }
}
