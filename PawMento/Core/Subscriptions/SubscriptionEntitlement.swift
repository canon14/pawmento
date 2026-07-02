import Foundation

/// Centralized plan → entitlement mapping for subscription features.
///
/// Keep `paidPlanTypes` in sync with `public.is_premium_subscription()` in schema.sql.
enum SubscriptionEntitlement {
    /// Paid plan identifiers issued by the server / billing system.
    static let paidPlanTypes: Set<String> = ["premium", "pro"]
    
    static let freePlanType = "free"
    
    /// Sentinel returned by server RPCs for unlimited coach quota.
    static let unlimitedCoachQuota = -1
    
    /// Whether the user has premium entitlements (unlimited coach, gated insights, etc.).
    /// Mirrors `public.is_premium_subscription(plan, sub_status)` in schema.sql.
    static func isPremium(planType: String, status: String) -> Bool {
        let plan = planType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let subStatus = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return subStatus == "active" || paidPlanTypes.contains(plan)
    }
    
    static func hasUnlimitedCoachQuestions(planType: String, status: String) -> Bool {
        isPremium(planType: planType, status: status)
    }
}
