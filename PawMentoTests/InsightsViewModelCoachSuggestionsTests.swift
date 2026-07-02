import XCTest
@testable import PawMento

final class InsightsViewModelCoachSuggestionsTests: XCTestCase {
    
    private func makeInsight(headline: String) -> Insight {
        Insight(
            id: UUID(),
            type: .correlation,
            tier: .moderate,
            headline: headline,
            narrative: "Test narrative",
            confidence: 0.8,
            evidenceCount: 5,
            visualization: VisualizationData(dataPoints: [1, 2], labels: nil, chartType: "sparkline"),
            actions: [],
            generatedAt: Date()
        )
    }
    
    func testDeriveCoachSuggestions_fromInsights() {
        let insights = [
            makeInsight(headline: "Scratching follows chicken meals"),
            makeInsight(headline: "Walks cluster on weekends")
        ]
        
        let suggestions = InsightsViewModel.deriveCoachSuggestions(
            from: insights,
            petName: "Buddy",
            signalCount: 10
        )
        
        XCTAssertEqual(suggestions.count, 2)
        XCTAssertTrue(suggestions[0].contains("Buddy"))
        XCTAssertTrue(suggestions[0].contains("Scratching follows chicken meals"))
    }
    
    func testDeriveCoachSuggestions_fallbackWhenNoInsights_butHasSignals() {
        let suggestions = InsightsViewModel.deriveCoachSuggestions(
            from: [],
            petName: "Luna",
            signalCount: 4
        )
        
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertTrue(suggestions[0].contains("recent logs"))
        XCTAssertTrue(suggestions[0].contains("Luna"))
    }
    
    func testDeriveCoachSuggestions_fallbackWhenNoData() {
        let suggestions = InsightsViewModel.deriveCoachSuggestions(
            from: [],
            petName: "Max",
            signalCount: 0
        )
        
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertTrue(suggestions[0].contains("log to build better insights"))
    }
    
    func testBreedBenchmarksDisabled() {
        XCTAssertFalse(InsightsViewModel.breedBenchmarksEnabled)
    }
}
