import Foundation

/// App Store product identifiers and their server-side plan mapping.
///
/// TODO(App Store Connect): Create matching auto-renewable subscription products before release.
/// TODO(StoreKit testing): Add PawMento.storekit to the Xcode scheme for local purchase testing.
enum SubscriptionProductIDs {
    /// Monthly Pro subscription — must match App Store Connect + StoreKit config.
    static let proMonthly = "com.ggozali.pawmento.devapp.pro.monthly"
    
    static let all: Set<String> = [proMonthly]
    
    /// Plan type written to `subscriptions.plan_type` after a verified purchase.
    static let serverPlanType = "pro"
    
    static func serverPlanType(for productID: String) -> String {
        switch productID {
        case proMonthly:
            return serverPlanType
        default:
            // Unknown product — default to pro until billing catalog is expanded.
            return serverPlanType
        }
    }
}
