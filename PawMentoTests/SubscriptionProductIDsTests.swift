import XCTest
@testable import PawMento

final class SubscriptionProductIDsTests: XCTestCase {
    
    func testProMonthlyProduct_mapsToProServerPlan() {
        XCTAssertEqual(
            SubscriptionProductIDs.serverPlanType(for: SubscriptionProductIDs.proMonthly),
            "pro"
        )
    }
    
    func testServerPlanType_isRecognizedAsPremium() {
        XCTAssertTrue(
            SubscriptionEntitlement.isPremium(
                planType: SubscriptionProductIDs.serverPlanType,
                status: "free"
            )
        )
    }
}
