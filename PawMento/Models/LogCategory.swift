import Foundation

enum LogCategory: String, CaseIterable, Identifiable, Codable {
    case meal = "Meal"
    case water = "Water"
    case potty = "Potty"
    case sleep = "Sleep"
    case walk = "Walk"
    case symptom = "Symptom"
    case med = "Med"
    case mood = "Mood"
    
    // More Categories
    case grooming = "Grooming"
    case vetVisit = "Vet Visit"
    case training = "Training"
    case play = "Play"
    case energy = "Energy Level"
    case appetite = "Appetite Change"
    case other = "Other"
    /// Unrecognized `log_type` from storage — not user-selectable; indicates schema drift.
    case unknown = "Unknown"
    
    var id: String { self.rawValue }
    
    /// Categories the user can pick when logging or creating reminders.
    static var selectableCategories: [LogCategory] {
        allCases.filter { $0 != .unknown }
    }
    
    var emoji: String {
        switch self {
        case .meal: return "🥩"
        case .water: return "💧"
        case .potty: return "💩"
        case .sleep: return "💤"
        case .walk: return "🦮"
        case .symptom: return "🤒"
        case .med: return "💊"
        case .mood: return "😊"
        case .grooming: return "🛁"
        case .vetVisit: return "🏥"
        case .training: return "🎯"
        case .play: return "🎾"
        case .energy: return "⚡️"
        case .appetite: return "🥣"
        case .other: return "🐾"
        case .unknown: return "❓"
        }
    }
    
    // The main 8 categories shown in the horizontal scroller
    static var quickCategories: [LogCategory] {
        [.meal, .water, .potty, .sleep, .walk, .symptom, .med, .mood]
    }
    
    /// Parses a category string from storage (DB defaults, notifications, legacy slugs).
    /// Accepts canonical `rawValue`, case-insensitive display names, and enum-case slugs (e.g. `"other"`).
    nonisolated static func fromStoredValue(_ value: String) -> LogCategory? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if let exact = LogCategory(rawValue: trimmed) {
            return exact
        }
        
        if let match = LogCategory.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(trimmed) == .orderedSame
        }) {
            return match
        }
        
        let slug = trimmed.lowercased().replacingOccurrences(of: " ", with: "_")
        if let match = LogCategory.allCases.first(where: {
            String(describing: $0).lowercased() == slug
        }) {
            return match
        }
        
        return nil
    }
    
    /// Canonical `rawValue` for persistence, when the stored string is recognized.
    static func canonicalStoredValue(from value: String) -> String? {
        fromStoredValue(value)?.rawValue
    }
    
    /// Resolves a stored `log_type` for decode paths. Known values normalize via `fromStoredValue`;
    /// unrecognized values map to `.unknown` and emit a debug-visible report (decode never fails).
    static func resolvingStoredLogType(_ value: String, context: String) -> LogCategory {
        if let resolved = fromStoredValue(value) {
            return resolved
        }
        reportUnrecognizedLogType(value, context: context)
        return .unknown
    }
    
    private static func reportUnrecognizedLogType(_ value: String, context: String) {
        #if DEBUG
        print("⚠️ LogCategory: Unrecognized log_type '\(value)' in \(context) — mapped to .unknown")
        #endif
    }
}

extension LogCategory {
    /// Wellness scoring buckets. Each `LogCategory` maps to at most one bucket via `wellnessScoringBucket`.
    enum WellnessScoringBucket {
        case routine
        case activity
    }
    
    /// Single source of truth for routine vs activity wellness scoring.
    /// Categories not in either bucket (symptom, med, mood, etc.) are excluded from adherence scoring.
    var wellnessScoringBucket: WellnessScoringBucket? {
        switch self {
        case .meal, .potty, .sleep, .water:
            return .routine
        case .walk, .play, .training:
            return .activity
        default:
            return nil
        }
    }
    
    static let activityCategories: Set<LogCategory> = Set(
        allCases.compactMap { $0.wellnessScoringBucket == .activity ? $0 : nil }
    )
    
    static let routineCategories: Set<LogCategory> = Set(
        allCases.compactMap { $0.wellnessScoringBucket == .routine ? $0 : nil }
    )
}
