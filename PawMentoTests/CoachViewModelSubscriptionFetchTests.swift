import XCTest
@testable import PawMento

@MainActor
final class CoachViewModelSubscriptionFetchTests: XCTestCase {
    
    override func tearDown() {
        SubscriptionStatusFetcher.fetchHandler = nil
        SubscriptionCache.clear()
        super.tearDown()
    }
    
    func testInitializeQuotaAndSubscription_onFetchError_preservesKnownPremium() async {
        let ownerId = UUID()
        SubscriptionStatusFetcher.fetchHandler = { _ in
            throw NSError(domain: "test", code: 1)
        }
        
        let viewModel = CoachViewModel()
        viewModel.isPremium = true
        viewModel.subscriptionLoadState = .loaded
        viewModel.freeQuestionsRemaining = SubscriptionEntitlement.unlimitedCoachQuota
        
        await viewModel.initializeQuotaAndSubscription(ownerId: ownerId, maxAttempts: 1)
        
        XCTAssertTrue(viewModel.isPremium)
        XCTAssertEqual(viewModel.freeQuestionsRemaining, SubscriptionEntitlement.unlimitedCoachQuota)
        XCTAssertEqual(viewModel.subscriptionLoadState, .failed)
        XCTAssertTrue(viewModel.showSubscriptionLoadError)
        XCTAssertFalse(viewModel.shouldEnforceFreeQuota)
    }
    
    func testInitializeQuotaAndSubscription_onFetchError_doesNotResetConfirmedFreeQuota() async {
        let ownerId = UUID()
        SubscriptionStatusFetcher.fetchHandler = { _ in
            throw NSError(domain: "test", code: 1)
        }
        
        let viewModel = CoachViewModel()
        viewModel.isPremium = false
        viewModel.subscriptionLoadState = .loaded
        viewModel.freeQuestionsRemaining = 2
        
        await viewModel.initializeQuotaAndSubscription(ownerId: ownerId, maxAttempts: 1)
        
        XCTAssertFalse(viewModel.isPremium)
        XCTAssertEqual(viewModel.freeQuestionsRemaining, 2)
        XCTAssertEqual(viewModel.subscriptionLoadState, .failed)
        XCTAssertTrue(viewModel.showSubscriptionLoadError)
        XCTAssertTrue(viewModel.shouldEnforceFreeQuota)
    }
    
    func testInitializeQuotaAndSubscription_onSuccess_setsLoadedState() async {
        let ownerId = UUID()
        SubscriptionStatusFetcher.fetchHandler = { _ in
            SubscriptionSnapshot(
                isPremium: true,
                freeQuestionsRemaining: SubscriptionEntitlement.unlimitedCoachQuota,
                resetLowQuotaWarning: false
            )
        }
        
        let viewModel = CoachViewModel()
        await viewModel.initializeQuotaAndSubscription(ownerId: ownerId, maxAttempts: 1)
        
        XCTAssertTrue(viewModel.isPremium)
        XCTAssertEqual(viewModel.subscriptionLoadState, .loaded)
        XCTAssertFalse(viewModel.showSubscriptionLoadError)
        XCTAssertEqual(SubscriptionCache.cachedIsPremium, true)
    }
}
