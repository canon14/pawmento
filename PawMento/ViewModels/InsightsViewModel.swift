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
    
    // View State
    enum ViewState: Equatable {
        case loading
        case noData
        case noDataForRange
        case noPatterns
        case offline
        case error(String)
        case success
    }
    @Published var viewState: ViewState = .loading
    
    // Entitlements
    @Published var isPremium: Bool = false // Toggle this for testing free vs premium
    
    // States
    enum DataMaturity {
        case new, building, mature
    }
    @Published var dataMaturity: DataMaturity = .mature
    
    init() {
        // Data loading is now triggered by onAppear in the View
    }
    
    func loadInsights(for pet: Pet?, forceRefresh: Bool = false) async {
        guard let pet = pet else { return }
        
        isAnalyzing = true
        viewState = .loading
        do {
            let fetchedInsights = try await InsightEngine.shared.generateInsights(for: pet, window: timeRange, forceRefresh: forceRefresh)
            
            if fetchedInsights.isEmpty {
                // Determine if it's noDataForRange vs noPatterns
                // For now, assume if engine returns empty, no patterns were found.
                // If we had 0 signals, we can call it noDataForRange.
                self.viewState = .noPatterns
            } else {
                self.viewState = .success
            }
            
            // Re-partition the insights for the UI
            self.heroInsight = fetchedInsights.first(where: { $0.tier == .strong })
            self.patternCards = fetchedInsights.filter { $0.id != self.heroInsight?.id }
            self.patternCount = fetchedInsights.count
            self.lastUpdated = Date()
            
            // Mock Benchmark since we don't have enough global users yet
            self.breedBenchmark = BreedBenchmark(
                breed: pet.breed ?? "Dog",
                age: 6,
                activityPercentile: 62,
                symptomsPercentile: 78,
                sleepPercentile: 51
            )
            
            // Mock Coach Suggestions
            self.coachSuggestions = [
                "Why is \(pet.name) coughing?",
                "Is his weight healthy?",
                "What should I bring to the vet?"
            ]
        } catch {
            print("Failed to load insights: \(error)")
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                self.viewState = .offline
            } else {
                self.viewState = .error(error.localizedDescription)
            }
        }
        isAnalyzing = false
    }
    
    func changeTimeRange(to range: TimeRange, for pet: Pet?) async {
        guard timeRange != range else { return }
        timeRange = range
        
        await loadInsights(for: pet)
    }
    
    func refreshInsights(for pet: Pet?) async {
        await loadInsights(for: pet, forceRefresh: true)
    }
    
    // Mock method removed
}
