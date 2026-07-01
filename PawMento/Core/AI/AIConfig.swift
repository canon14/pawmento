import Foundation

enum AIConfig {
    static let haikuModel = "claude-haiku-4-5-20251001"
    static let anthropicVersion = "2023-06-01"
    static let requestTimeout: TimeInterval = 30.0  // Fix C2: Now used by AICoachClient.proxySession
    static let maxRetries: Int = 3                   // Fix C2: Now used by retry loop
    static let maxResponseTokens: Int = 2048         // Fix C3: Raised from 1024 to reduce truncation
    
    // Fix C8 + AI-L3: Emergency contacts, region-aware.
    // ASPCA is US-only; other locales get a generic fallback.
    enum EmergencyContacts {
        /// Whether the device locale is in the US
        static var isUS: Bool {
            Locale.current.region?.identifier == "US"
        }
        
        // US-specific: ASPCA Animal Poison Control Center
        static let aspcaPoisonControl = "(888) 426-4435"
        static let aspcaFee = "$95"
        
        /// The name of the poison control resource, labeled for the user's region.
        static var poisonControlName: String {
            if isUS {
                return "ASPCA Animal Poison Control Center"
            }
            return "your local animal poison control hotline"
        }
        
        /// The phone number to display, or nil for non-US locales.
        static var poisonControlNumber: String? {
            if isUS {
                return aspcaPoisonControl
            }
            return nil
        }
        
        /// Fee note (US-only).
        static var feeNote: String? {
            if isUS {
                return aspcaFee
            }
            return nil
        }
        
        /// A full emergency contact string suitable for display in prompts/UI.
        static var emergencyContactBlurb: String {
            if isUS {
                return "\(poisonControlName) at \(aspcaPoisonControl) (a \(aspcaFee) fee applies but is highly recommended)"
            }
            return "your local animal poison control hotline or emergency veterinarian (search online for the number in your region)"
        }
        
        // Kept for backward compatibility in prompt interpolation
        static var aspcaNote: String { poisonControlName }
    }
}
