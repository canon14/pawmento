import Foundation
import SwiftUI
import CryptoKit

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
    
    // Priority: strong > moderate > emerging > positive (lower number = higher priority)
    nonisolated var priority: Int {
        switch self {
        case .strong: return 0
        case .moderate: return 1
        case .emerging: return 2
        case .positive: return 3
        }
    }
    
    var label: String {
        switch self {
        case .strong: return "STRONG PATTERN"
        case .moderate: return "MODERATE PATTERN"
        case .emerging: return "EMERGING PATTERN"
        case .positive: return "POSITIVE"
        }
    }
    
    var iconName: String {
        switch self {
        case .strong: return "bolt.fill"
        case .moderate: return "chart.line.uptrend.xyaxis"
        case .emerging: return "sparkles"
        case .positive: return "checkmark.seal.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .strong: return .yellow
        case .moderate: return .orange
        case .emerging: return .gray
        case .positive: return .green
        }
    }
    
    nonisolated static func < (lhs: ConfidenceTier, rhs: ConfidenceTier) -> Bool {
        return lhs.priority < rhs.priority
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
    
    /// Deterministic id so dismissals survive engine regenerations.
    /// Uses detector-stable fields (not LLM-rewritten headlines).
    nonisolated static func stableId(
        type: InsightType,
        evidenceCount: Int,
        isRuleBased: Bool,
        fingerprint: String
    ) -> UUID {
        let material = "\(type.rawValue)|\(evidenceCount)|\(isRuleBased)|\(fingerprint)"
        let digest = Insecure.MD5.hash(data: Data(material.utf8))
        var bytes = Array(digest)
        bytes[6] = (bytes[6] & 0x0F) | 0x30
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
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
