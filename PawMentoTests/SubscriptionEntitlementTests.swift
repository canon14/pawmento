import XCTest
@testable import PawMento

final class SubscriptionEntitlementTests: XCTestCase {
    
    func testActiveProPlan_isPremium() {
        XCTAssertTrue(SubscriptionEntitlement.isPremium(planType: "pro", status: "active"))
    }
    
    func testActivePremiumPlan_isPremium() {
        XCTAssertTrue(SubscriptionEntitlement.isPremium(planType: "premium", status: "active"))
    }
    
    func testExpiredProPlan_isNotPremium() {
        XCTAssertFalse(SubscriptionEntitlement.isPremium(planType: "pro", status: "expired"))
    }
    
    func testProPlanWithInactiveStatus_isNotPremium() {
        XCTAssertFalse(SubscriptionEntitlement.isPremium(planType: "pro", status: "free"))
    }
    
    func testActiveFreePlan_isNotPremium() {
        XCTAssertFalse(SubscriptionEntitlement.isPremium(planType: "free", status: "active"))
    }
    
    func testFreePlan_isNotPremium() {
        XCTAssertFalse(SubscriptionEntitlement.isPremium(planType: "free", status: "free"))
    }
    
    func testActiveProPlan_caseInsensitive() {
        XCTAssertTrue(SubscriptionEntitlement.isPremium(planType: "PRO", status: "ACTIVE"))
    }
    
    func testActiveProPlan_withPastPeriodEnd_isNotPremium() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(
            SubscriptionEntitlement.isPremium(
                planType: "pro",
                status: "active",
                periodEnd: yesterday
            )
        )
    }
    
    func testActiveProPlan_withFuturePeriodEnd_isPremium() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertTrue(
            SubscriptionEntitlement.isPremium(
                planType: "pro",
                status: "active",
                periodEnd: tomorrow
            )
        )
    }
    
    func testPaidPlanTypes_containsProAndPremium() {
        XCTAssertTrue(SubscriptionEntitlement.paidPlanTypes.contains("pro"))
        XCTAssertTrue(SubscriptionEntitlement.paidPlanTypes.contains("premium"))
        XCTAssertFalse(SubscriptionEntitlement.paidPlanTypes.contains("free"))
    }
    
    func testHasUnlimitedCoachQuestions_matchesIsPremium() {
        XCTAssertTrue(
            SubscriptionEntitlement.hasUnlimitedCoachQuestions(planType: "pro", status: "active")
        )
        XCTAssertFalse(
            SubscriptionEntitlement.hasUnlimitedCoachQuestions(planType: "pro", status: "expired")
        )
    }
    
    func testFreeQuestionsRemaining_derivesFromQuotaAndUsage() {
        XCTAssertEqual(SubscriptionEntitlement.freeQuestionsRemaining(questionsUsed: 0), 5)
        XCTAssertEqual(SubscriptionEntitlement.freeQuestionsRemaining(questionsUsed: 3), 2)
        XCTAssertEqual(SubscriptionEntitlement.freeQuestionsRemaining(questionsUsed: 5), 0)
        XCTAssertEqual(SubscriptionEntitlement.freeQuestionsRemaining(questionsUsed: 99), 0)
    }
}
