import Foundation

struct SafetyClassifier {
    
    /*
     UNIT TEST EXAMPLES:
     - True Positive: "my dog ate chocolate" -> TRUE (Matches keyword "chocolate")
     - Negation: "did not eat chocolate" -> FALSE ("did not" captured in Group 1, safely ignored)
     - Benign Substring: "my companion" -> FALSE (Word boundaries prevent "onion" matching inside "companion")
     - Newly-added term: "he has pale gums" -> TRUE (Matches keyword "pale gums")
     */
    
    // MARK: - Keyword Categories
    
    static let toxins = [
        "chocolate", "grape", "grapes", "raisin", "raisins", "xylitol",
        "onion", "onions", "garlic", "macadamia", "poison", "antifreeze", 
        "rat poison", "lily", "lilies", "ibuprofen", "tylenol", 
        "acetaminophen", "advil"
    ]
    
    static let trauma = [
        "hit by car", "seizure", "seizures", "seizing", "choking", "choked", 
        "unconscious", "won't wake up", "collapsed", "collapse"
    ]
    
    static let clinicalSigns = [
        "bloat", "bloated stomach", "gdv", "profuse bleeding", 
        "bleeding profusely", "vomiting blood", "blood in stool", 
        "can't breathe", "not breathing", "stopped breathing", 
        "pale gums", "blue gums", "straining to urinate", 
        "lethargic and not eating"
    ]
    
    static let allKeywords = toxins + trauma + clinicalSigns
    
    // MARK: - Regex Compilation
    
    // Compiled once to ensure <50ms execution on the main thread
    private static let emergencyRegex: NSRegularExpression = {
        let keywordsPattern = allKeywords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        let negations = ["not", "no", "didn't", "did not", "hasn't", "won't"]
        let negationsPattern = negations.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        
        // Matches an optional negation up to 3 words prior, then the keyword.
        // We use \s+ instead of \W+ for the gap to prevent negating across punctuation (e.g. "no, he ate chocolate").
        // Group 1: Negation (if present)
        // Group 2: Keyword
        let pattern = "(?:\\b(\(negationsPattern))\\b(?:\\s+\\w+){0,3}\\s+)?\\b(\(keywordsPattern))\\b"
        
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()
    
    // MARK: - Public API
    
    /// Returns true if the message triggers deterministic emergency routing
    static func isEmergency(message: String) -> Bool {
        let range = NSRange(location: 0, length: message.utf16.count)
        let matches = emergencyRegex.matches(in: message, options: [], range: range)
        
        for match in matches {
            // If Group 1 (the negation) is NOT found, we have an un-negated emergency keyword.
            if match.range(at: 1).location == NSNotFound {
                return true
            }
        }
        
        return false
    }
}
