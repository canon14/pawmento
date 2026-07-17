import Foundation

/// Presentation context for event-triggered and manual paywall surfaces.
enum PaywallTrigger: Equatable {
    case firstStrongInsight
    case coachQuotaExhausted
    case manual(featureContext: String?)
}
