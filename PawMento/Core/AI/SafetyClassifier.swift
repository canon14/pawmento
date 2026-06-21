import Foundation

struct SafetyClassifier {
    
    /*
     SAFETY DESIGN:
     This classifier is a PREFILTER — it runs deterministically in <50ms before any LLM call.
     It is NOT the last line of defense: the AI Coach system prompt also instructs the LLM to
     escalate emergencies. A false positive (extra "see a vet" prompt) is vastly preferable
     to a false negative (missed emergency).
     
     NEGATION POLICY (Fix I7):
     For TOXINS: Only suppress on tight, unambiguous consumption-negation patterns like
     "did not eat <toxin>", "didn't eat <toxin>", "hasn't eaten <toxin>".
     For TRAUMA & CLINICAL SIGNS: NEVER suppress — there is no benign interpretation
     of "not seizing" or "no idea why he collapsed" that should prevent emergency routing.
     
     LOCALIZATION: English-only for now. Non-English support is a follow-up.
     */
    
    // MARK: - Keyword Categories
    
    static let toxins = [
        "chocolate", "grape", "grapes", "raisin", "raisins", "xylitol",
        "onion", "onions", "garlic", "macadamia", "poison", "antifreeze", 
        "rat poison", "rat bait", "snail bait",
        "lily", "lilies", "ibuprofen", "tylenol", 
        "acetaminophen", "advil",
        "bleach", "cleaning product",
        "ate something", "swallowed"
    ]
    
    static let trauma = [
        "hit by car", "hit by a car", "seizure", "seizures", "seizing",
        "choking", "choked", 
        "unconscious", "won't wake up", "collapsed", "collapse",
        "fell from", "attacked by"
    ]
    
    static let clinicalSigns = [
        "bloat", "bloated stomach", "gdv", "profuse bleeding", 
        "bleeding profusely", "vomiting blood", "blood in stool", 
        "can't breathe", "not breathing", "stopped breathing",
        "difficulty breathing",
        "pale gums", "blue gums", "straining to urinate", 
        "lethargic and not eating",
        "swollen abdomen", "distended belly",
        "won't stop vomiting", "continuous vomiting",
        "unable to stand", "dragging legs"
    ]
    
    // MARK: - Compiled Patterns
    
    // Fix I7: Toxin-specific negation — only suppress on tight consumption-negation patterns.
    // Pattern: "did not eat|didn't eat|hasn't eaten|never ate" immediately before a toxin keyword.
    // This is much tighter than the old 3-word-gap approach.
    private static let toxinNegationPrefixes = [
        "did not eat", "didn't eat", "hasn't eaten", "never ate",
        "did not consume", "didn't consume", "hasn't consumed",
        "did not ingest", "didn't ingest", "hasn't ingested",
        "did not swallow", "didn't swallow"
    ]
    
    // Toxin regex: match negated toxin or plain toxin
    private static let toxinRegex: NSRegularExpression = {
        let toxinPattern = toxins.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        let negPattern = toxinNegationPrefixes.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        // Group 1: tight negation prefix (if present), Group 2: toxin keyword
        let pattern = "(?:\\b(\(negPattern))\\s+)?\\b(\(toxinPattern))\\b"
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()
    
    // Trauma + clinical signs regex: NO negation suppression at all (Fix I7)
    private static let urgentRegex: NSRegularExpression = {
        let allUrgent = trauma + clinicalSigns
        let urgentPattern = allUrgent.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        let pattern = "\\b(\(urgentPattern))\\b"
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()
    
    // MARK: - Public API
    
    /// Returns true if the message triggers deterministic emergency routing.
    /// Biased toward recall (false positives preferred over false negatives).
    static func isEmergency(message: String) -> Bool {
        let range = NSRange(location: 0, length: message.utf16.count)
        
        // 1. Check trauma & clinical signs — NEVER suppressed by negation
        let urgentMatches = urgentRegex.matches(in: message, options: [], range: range)
        if !urgentMatches.isEmpty {
            return true
        }
        
        // 2. Check toxins — only suppressed by tight consumption-negation prefix
        let toxinMatches = toxinRegex.matches(in: message, options: [], range: range)
        for match in toxinMatches {
            // If Group 1 (tight negation prefix) is NOT found, this is an un-negated toxin mention
            if match.range(at: 1).location == NSNotFound {
                return true
            }
            // If negation IS found, this specific match is suppressed — but keep checking others
        }
        
        return false
    }
}
