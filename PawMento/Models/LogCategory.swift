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
    
    var id: String { self.rawValue }
    
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
        }
    }
    
    // The main 8 categories shown in the horizontal scroller
    static var quickCategories: [LogCategory] {
        [.meal, .water, .potty, .sleep, .walk, .symptom, .med, .mood]
    }
}

extension LogCategory {
    // Canonical set for "Activity"
    static let activityCategories: Set<LogCategory> = [.walk, .play, .training]
    
    // Canonical set for "Routine"
    static let routineCategories: Set<LogCategory> = [.meal, .potty, .sleep, .water]
}
