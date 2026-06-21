import Foundation

enum AIConfig {
    static let haikuModel = "claude-haiku-4-5-20251001"
    static let anthropicVersion = "2023-06-01"
    static let requestTimeout: TimeInterval = 30.0  // Fix C2: Now used by AICoachClient.proxySession
    static let maxRetries: Int = 3                   // Fix C2: Now used by retry loop
    static let maxResponseTokens: Int = 2048         // Fix C3: Raised from 1024 to reduce truncation
    
    // Fix C8: Emergency contacts extracted from hardcoded prompt text.
    // Localize or source from remote config for non-US users.
    enum EmergencyContacts {
        static let aspcaPoisonControl = "(888) 426-4435"
        static let aspcaFee = "$95"
        static let aspcaNote = "ASPCA Animal Poison Control Center"
    }
}
