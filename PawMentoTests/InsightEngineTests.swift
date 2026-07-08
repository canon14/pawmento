import XCTest
@testable import PawMento

final class InsightEngineTests: XCTestCase {
    
    private let petId = UUID()
    
    private lazy var testPet = Pet(
        id: petId,
        name: "Rex",
        species: .dog
    )
    
    override func tearDown() async throws {
        SignalLoader.loadHandler = nil
        await InsightEngine.shared.resetForTesting()
        try await super.tearDown()
    }
    
    func testConcurrentGenerateInsights_coalescesInFlightWork() async throws {
        await InsightEngine.shared.resetForTesting(pipelineDelayNanoseconds: 200_000_000)
        await InsightEngine.shared.clearCache(for: petId)
        
        var loadInvocationCount = 0
        SignalLoader.loadHandler = { _, _ in
            loadInvocationCount += 1
            try await Task.sleep(nanoseconds: 50_000_000)
            return []
        }
        
        async let first = InsightEngine.shared.generateInsights(
            for: testPet,
            window: .days30,
            forceRefresh: true
        )
        async let second = InsightEngine.shared.generateInsights(
            for: testPet,
            window: .days30,
            forceRefresh: true
        )
        
        let (resultA, resultB) = try await (first, second)
        
        let pipelineCount = await InsightEngine.shared.pipelineExecutionCountForTesting()
        XCTAssertEqual(
            pipelineCount,
            1,
            "Concurrent requests for the same key should run the pipeline once"
        )
        XCTAssertEqual(loadInvocationCount, 1, "SignalLoader should be invoked once")
        XCTAssertEqual(resultA.signalCount, resultB.signalCount)
        XCTAssertEqual(resultA.insights.count, resultB.insights.count)
    }
    
    func testConcurrentGenerateInsights_differentWindows_runSeparately() async throws {
        await InsightEngine.shared.resetForTesting()
        
        var loadInvocationCount = 0
        SignalLoader.loadHandler = { _, _ in
            loadInvocationCount += 1
            return []
        }
        
        async let days7 = InsightEngine.shared.generateInsights(
            for: testPet,
            window: .days7,
            forceRefresh: true
        )
        async let days30 = InsightEngine.shared.generateInsights(
            for: testPet,
            window: .days30,
            forceRefresh: true
        )
        
        _ = try await (days7, days30)
        
        let pipelineCount = await InsightEngine.shared.pipelineExecutionCountForTesting()
        XCTAssertEqual(
            pipelineCount,
            2,
            "Different window keys should not coalesce"
        )
        XCTAssertEqual(loadInvocationCount, 2)
    }
    
    // MARK: - I12: Cache invalidation on log mutations
    
    func testClearCache_invalidatesOnlyTargetPet() async throws {
        await InsightEngine.shared.resetForTesting()
        SignalLoader.loadHandler = { _, _ in [] }
        
        let petA = UUID()
        let petB = UUID()
        let modelA = Pet(id: petA, name: "A", species: .dog)
        let modelB = Pet(id: petB, name: "B", species: .cat)
        
        _ = try await InsightEngine.shared.generateInsights(for: modelA, window: .days30, forceRefresh: true)
        _ = try await InsightEngine.shared.generateInsights(for: modelB, window: .days30, forceRefresh: true)
        
        let cachedABefore = await InsightEngine.shared.isCachedForTesting(petId: petA, window: .days30)
        let cachedBBefore = await InsightEngine.shared.isCachedForTesting(petId: petB, window: .days30)
        XCTAssertTrue(cachedABefore)
        XCTAssertTrue(cachedBBefore)
        
        await InsightEngine.shared.clearCache(for: petA)
        
        let cachedAAfter = await InsightEngine.shared.isCachedForTesting(petId: petA, window: .days30)
        let cachedBAfter = await InsightEngine.shared.isCachedForTesting(petId: petB, window: .days30)
        XCTAssertFalse(cachedAAfter)
        XCTAssertTrue(cachedBAfter)
    }
    
    func testClearCache_forcesRecomputeOnNextRequest() async throws {
        await InsightEngine.shared.resetForTesting()
        SignalLoader.loadHandler = { _, _ in [] }
        
        let pet = Pet(id: petId, name: "Rex", species: .dog)
        
        _ = try await InsightEngine.shared.generateInsights(for: pet, window: .days30, forceRefresh: true)
        let cachedBeforeClear = await InsightEngine.shared.isCachedForTesting(petId: petId, window: .days30)
        XCTAssertTrue(cachedBeforeClear)
        
        let runsBeforeClear = await InsightEngine.shared.pipelineExecutionCountForTesting()
        await InsightEngine.shared.clearCache(for: petId)
        let cachedAfterClear = await InsightEngine.shared.isCachedForTesting(petId: petId, window: .days30)
        XCTAssertFalse(cachedAfterClear)
        
        _ = try await InsightEngine.shared.generateInsights(for: pet, window: .days30)
        
        let runsAfter = await InsightEngine.shared.pipelineExecutionCountForTesting()
        XCTAssertEqual(runsAfter, runsBeforeClear + 1, "Cleared cache should miss and re-run the pipeline")
    }
    
    func testClearCache_duringInFlight_skipsStaleCacheWrite() async throws {
        await InsightEngine.shared.resetForTesting(pipelineDelayNanoseconds: 200_000_000)
        SignalLoader.loadHandler = { _, _ in [] }
        
        let pet = Pet(id: petId, name: "Rex", species: .dog)
        
        let inFlight = Task {
            try await InsightEngine.shared.generateInsights(for: pet, window: .days30, forceRefresh: true)
        }
        
        try await Task.sleep(nanoseconds: 50_000_000)
        await InsightEngine.shared.clearCache(for: petId)
        
        do {
            _ = try await inFlight.value
        } catch is CancellationError {
            // Expected when clearCache cancels the in-flight generation.
        }
        let cachedAfterInFlight = await InsightEngine.shared.isCachedForTesting(petId: petId, window: .days30)
        XCTAssertFalse(
            cachedAfterInFlight,
            "Cache cleared mid-flight must not be repopulated with stale results"
        )
    }
}
