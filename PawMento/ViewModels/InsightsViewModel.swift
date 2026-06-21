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
            let result = try await InsightEngine.shared.generateInsights(for: pet, window: timeRange, forceRefresh: forceRefresh)
            let fetchedInsights = result.insights
            
            if result.signalCount == 0 {
                self.viewState = .noDataForRange
            } else if fetchedInsights.isEmpty {
                self.viewState = .noPatterns
            } else {
                self.viewState = .success
            }
            
            // Re-partition the insights for the UI
            self.heroInsight = bestInsight(from: fetchedInsights)
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
                "Is \(pet.name)'s weight healthy?",
                "What should I ask the vet about \(pet.name)?",
                "How much daily activity does \(pet.name) need?"
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
    
    enum DismissReason {
        case resolved
        case notRelevant
    }
    
    func dismissInsight(_ insight: Insight, reason: DismissReason) {
        // In a real app, we would log this to telemetry and update the database
        // For now, we just remove it from the UI
        if heroInsight?.id == insight.id {
            heroInsight = bestInsight(from: patternCards)
            if let newHero = heroInsight {
                patternCards.removeAll { $0.id == newHero.id }
            }
        } else {
            patternCards.removeAll { $0.id == insight.id }
        }
        
        patternCount = patternCards.count + (heroInsight != nil ? 1 : 0)
        
        // If everything is dismissed, show empty state
        if heroInsight == nil && patternCards.isEmpty {
            viewState = .noPatterns
        }
    }
    
    private func bestInsight(from insights: [Insight]) -> Insight? {
        return insights.min(by: { 
            if $0.tier.priority == $1.tier.priority {
                return $0.confidence > $1.confidence
            }
            return $0.tier.priority < $1.tier.priority
        })
    }
}
