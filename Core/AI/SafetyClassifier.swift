import Foundation

struct SafetyClassifier {
    // Deterministic keyword matching that runs in <50ms before hitting the LLM
    static let emergencyKeywords = [
        "chocolate", "grapes", "raisins", "xylitol", "onions", "garlic", "macadamia",
        "bloat", "gdv", "seizure", "unconscious", "hit by car", "profuse bleeding",
        "can't breathe", "choking", "poison", "antifreeze", "rat poison", "straining to urinate"
    ]
    
    /// Returns true if the message triggers deterministic emergency routing
    static func isEmergency(message: String) -> Bool {
        let lowercased = message.lowercased()
        for keyword in emergencyKeywords {
            if lowercased.contains(keyword) {
                return true
            }
        }
        return false
    }
}
