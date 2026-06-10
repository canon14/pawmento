import Foundation
import SwiftUI
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {
    var petId: UUID?
    
    @Published var timeRange: TimeRange = .days30
    
    // Insight collection
    @Published var heroInsight: Insight?
    @Published var patternCards: [Insight] = []
    @Published var breedBenchmark: BreedBenchmark?
    @Published var coachSuggestions: [String] = []
    
    // Meta
    @Published var patternCount: Int = 0
    @Published var lastUpdated: Date = Date()
    @Published var isAnalyzing: Bool = false
    
    // Entitlements
    @Published var isPremium: Bool = false // Toggle this for testing free vs premium
    
    // States
    enum DataMaturity {
        case new, building, mature
    }
    @Published var dataMaturity: DataMaturity = .mature
    
    init() {
        // Load mock data on init for now
        loadMockInsights()
    }
    
    func changeTimeRange(to range: TimeRange) {
        guard timeRange != range else { return }
        timeRange = range
        
        // Simulate network/compute delay
        isAnalyzing = true
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 600ms skeleton shimmer
            loadMockInsights()
            isAnalyzing = false
        }
    }
    
    func refreshInsights() async {
        isAnalyzing = true
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        loadMockInsights()
        isAnalyzing = false
    }
    
    private func loadMockInsights() {
        // Mock Hero (Strong)
        heroInsight = Insight(
            id: UUID(),
            type: .correlation,
            tier: .strong,
            headline: "Coughing correlates with the new food",
            narrative: "Buddy has coughed 6× in the 11 days since you switched to the salmon kibble. Pre-switch baseline: 0.3 events/week.",
            confidence: 0.87,
            evidenceCount: 6,
            visualization: VisualizationData(dataPoints: [0, 0, 1, 0, 1, 0, 2, 0, 1, 3, 2], labels: ["Mar 1", "Mar 11", "Today"], chartType: "sparkline"),
            actions: [
                InsightAction(title: "Suggest action ›", isPrimary: true),
                InsightAction(title: "Share with vet ›", isPrimary: false)
            ],
            generatedAt: Date()
        )
        
        // Mock Other Patterns
        let moderate = Insight(
            id: UUID(),
            type: .temporal,
            tier: .moderate,
            headline: "Limping happens mostly on evenings",
            narrative: "4 of 5 episodes occurred between 5–9pm.",
            confidence: 0.76,
            evidenceCount: 5,
            visualization: VisualizationData(dataPoints: [0, 0, 1, 4, 0], labels: ["Morning", "Noon", "Aftn", "Eve", "Night"], chartType: "bar"),
            actions: [InsightAction(title: "Share with vet ›", isPrimary: false)],
            generatedAt: Date()
        )
        
        let positive = Insight(
            id: UUID(),
            type: .positive,
            tier: .positive,
            headline: "Best walking streak this month",
            narrative: "12 days in a row, averaging 38 min.",
            confidence: 1.0,
            evidenceCount: 12,
            visualization: VisualizationData(dataPoints: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], labels: nil, chartType: "streak"),
            actions: [InsightAction(title: "Share streak ›", isPrimary: true)],
            generatedAt: Date()
        )
        
        let emerging = Insight(
            id: UUID(),
            type: .trend,
            tier: .emerging,
            headline: "Possible sleep pattern shift",
            narrative: "Bedtime drifted 45 min later over 14 days. Confidence: 62% — keep logging to confirm.",
            confidence: 0.62,
            evidenceCount: 14,
            visualization: VisualizationData(dataPoints: [8.5, 8.4, 8.4, 8.2, 8.1, 8.1, 7.9, 7.8], labels: nil, chartType: "line"),
            actions: [InsightAction(title: "Keep logging ›", isPrimary: false)],
            generatedAt: Date()
        )
        
        patternCards = [moderate, positive, emerging]
        patternCount = 4
        lastUpdated = Date()
        
        // Mock Benchmark
        breedBenchmark = BreedBenchmark(
            breed: "Golden Retrievers",
            age: 6,
            activityPercentile: 62,
            symptomsPercentile: 78,
            sleepPercentile: 51
        )
        
        // Mock Coach Suggestions
        coachSuggestions = [
            "Why is Buddy coughing?",
            "Is his weight healthy?",
            "What should I bring to the vet?"
        ]
    }
}
