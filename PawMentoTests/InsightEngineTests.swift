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
}
