import Foundation

enum InsightType: String, Codable {
    case correlation
    case temporal
    case trend
    case positive
}

enum ConfidenceTier: String, Codable, Comparable {
    case strong
    case moderate
    case positive
    case emerging
    
    // Custom sort order for priority: strong > moderate > positive > emerging
    var sortOrder: Int {
        switch self {
        case .strong: return 0
        case .moderate: return 1
        case .positive: return 2
        case .emerging: return 3
        }
    }
    
    static func < (lhs: ConfidenceTier, rhs: ConfidenceTier) -> Bool {
        return lhs.sortOrder < rhs.sortOrder
    }
}

enum TimeRange: String, CaseIterable, Equatable {
    case days7 = "7d"
    case days30 = "30d"
    case days90 = "90d"
    case months6 = "6mo"
    case year1 = "1yr"
    case all = "All"
}

struct InsightAction: Identifiable, Codable, Hashable {
    var id = UUID()
    let title: String
    let isPrimary: Bool
}

struct VisualizationData: Codable, Hashable {
    // For mocked charts
    let dataPoints: [Double]
    let labels: [String]?
    let chartType: String // "sparkline", "bar", "streak"
}

struct Insight: Identifiable, Codable, Hashable {
    let id: UUID
    let type: InsightType
    let tier: ConfidenceTier
    let headline: String
    let narrative: String
    let confidence: Double
    let evidenceCount: Int
    let visualization: VisualizationData
    let actions: [InsightAction]
    let generatedAt: Date
    
    var isPremiumGated: Bool {
        switch tier {
        case .positive, .emerging:
            return false
        case .moderate, .strong:
            return true
        }
    }
}

struct BreedBenchmark: Identifiable, Codable {
    var id = UUID()
    let breed: String
    let age: Int
    let activityPercentile: Int
    let symptomsPercentile: Int
    let sleepPercentile: Int
}
