import Foundation

/// Once-only and cooldown gates for event-triggered paywall presentation.
enum PaywallEventGate {
    private static let firstStrongInsightPrefix = "firstStrongInsightPaywallShown_"
    private static let coachQuotaDismissedAtKey = "coachQuotaPaywallDismissedAt"
    private static let coachQuotaCooldown: TimeInterval = 24 * 60 * 60
    
    static func strongInsight(in insights: [Insight]) -> Insight? {
        insights.first { $0.tier == .strong }
    }
    
    static func shouldPresentFirstStrongInsight(userId: UUID) -> Bool {
        !UserDefaults.standard.bool(forKey: firstStrongInsightPrefix + userId.uuidString)
    }
    
    static func markFirstStrongInsightPresented(userId: UUID) {
        UserDefaults.standard.set(true, forKey: firstStrongInsightPrefix + userId.uuidString)
    }
    
    /// Atomically claims the once-only first-strong paywall. Returns `false` if already claimed.
    @discardableResult
    static func claimFirstStrongInsightIfEligible(userId: UUID) -> Bool {
        let key = firstStrongInsightPrefix + userId.uuidString
        if UserDefaults.standard.bool(forKey: key) {
            return false
        }
        UserDefaults.standard.set(true, forKey: key)
        return true
    }
    
    static func shouldPresentCoachQuotaExhausted(now: Date = Date()) -> Bool {
        let dismissedAt = UserDefaults.standard.double(forKey: coachQuotaDismissedAtKey)
        guard dismissedAt > 0 else { return true }
        return now.timeIntervalSince1970 - dismissedAt >= coachQuotaCooldown
    }
    
    static func markCoachQuotaPaywallDismissed(now: Date = Date()) {
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: coachQuotaDismissedAtKey)
    }
}
