import XCTest
@testable import PawMento

final class SubscriptionEntitlementTests: XCTestCase {
    
    func testProPlan_isPremium() {
        XCTAssertTrue(SubscriptionEntitlement.isPremium(planType: "pro", status: "free"))
    }
    
    func testPremiumPlan_isPremium() {
        XCTAssertTrue(SubscriptionEntitlement.isPremium(planType: "premium", status: "free"))
    }
    
    func testActiveStatus_isPremium() {
        XCTAssertTrue(SubscriptionEntitlement.isPremium(planType: "free", status: "active"))
    }
    
    func testFreePlan_isNotPremium() {
        XCTAssertFalse(SubscriptionEntitlement.isPremium(planType: "free", status: "free"))
    }
    
    func testProPlan_caseInsensitive() {
        XCTAssertTrue(SubscriptionEntitlement.isPremium(planType: "PRO", status: "free"))
    }
    
    func testPaidPlanTypes_containsProAndPremium() {
        XCTAssertTrue(SubscriptionEntitlement.paidPlanTypes.contains("pro"))
        XCTAssertTrue(SubscriptionEntitlement.paidPlanTypes.contains("premium"))
        XCTAssertFalse(SubscriptionEntitlement.paidPlanTypes.contains("free"))
    }
    
    func testHasUnlimitedCoachQuestions_matchesIsPremium() {
        XCTAssertTrue(SubscriptionEntitlement.hasUnlimitedCoachQuestions(planType: "pro", status: "free"))
        XCTAssertFalse(SubscriptionEntitlement.hasUnlimitedCoachQuestions(planType: "free", status: "free"))
    }
}
