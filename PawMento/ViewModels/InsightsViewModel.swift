import Foundation
import SwiftUI
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {
    /// Population breed benchmarks require cohort data — disabled until backend support lands.
    static let breedBenchmarksEnabled = false
    
    private(set) var petId: UUID?
    private var loadRequestId = UUID()
    
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
        
        let requestId = UUID()
        loadRequestId = requestId
        let loadingPetId = pet.id
        
        if petId != nil && petId != loadingPetId {
            clearDisplayedInsights()
        }
        petId = loadingPetId
        
        isAnalyzing = true
        viewState = .loading
        
        // Fix S16: Load dismissed insight IDs for this pet
        let dismissedIds = Self.loadDismissedIds(for: pet.id)
        
        do {
            let result = try await InsightEngine.shared.generateInsights(for: pet, window: timeRange, forceRefresh: forceRefresh)
            
            guard loadRequestId == requestId, petId == loadingPetId else { return }
            
            // Fix S16: Filter out dismissed insights
            let fetchedInsights = result.insights.filter { !dismissedIds.contains($0.id) }
            
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
            // Fix S16: Consistent count from the actual displayed set
            self.patternCount = patternCards.count + (heroInsight != nil ? 1 : 0)
            self.lastUpdated = Date()
            
            self.breedBenchmark = nil
            
            let displayedInsights = [heroInsight].compactMap { $0 } + patternCards
            self.coachSuggestions = Self.deriveCoachSuggestions(
                from: displayedInsights,
                petName: pet.name,
                signalCount: result.signalCount
            )
        } catch {
            guard loadRequestId == requestId, petId == loadingPetId else { return }
            
            print("Failed to load insights: \(error)")
            clearDisplayedInsights()
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                self.viewState = .offline
            } else {
                self.viewState = .error(error.localizedDescription)
            }
        }
        
        if loadRequestId == requestId {
            isAnalyzing = false
        }
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
    
    // Fix S16: Persist dismissed insight IDs so they don't resurface on refresh
    func dismissInsight(_ insight: Insight, reason: DismissReason, petId: UUID?) {
        // Persist the dismissal
        if let petId = petId {
            var dismissed = Self.loadDismissedIds(for: petId)
            dismissed.insert(insight.id)
            Self.saveDismissedIds(dismissed, for: petId)
        }
        
        // Update UI state
        if heroInsight?.id == insight.id {
            heroInsight = bestInsight(from: patternCards)
            if let newHero = heroInsight {
                patternCards.removeAll { $0.id == newHero.id }
            }
        } else {
            patternCards.removeAll { $0.id == insight.id }
        }
        
        // Fix S16: Recompute count consistently from the actual displayed set
        patternCount = patternCards.count + (heroInsight != nil ? 1 : 0)
        
        // If everything is dismissed, show empty state
        if heroInsight == nil && patternCards.isEmpty {
            viewState = .noPatterns
        }
    }
    
    private func clearDisplayedInsights() {
        heroInsight = nil
        patternCards = []
        patternCount = 0
        breedBenchmark = nil
        coachSuggestions = []
    }
    
    private func bestInsight(from insights: [Insight]) -> Insight? {
        InsightOrdering.bestInsight(from: insights)
    }
    
    /// Builds coach prompt chips from surfaced insights, with honest fallbacks when none exist.
    static func deriveCoachSuggestions(
        from insights: [Insight],
        petName: String,
        signalCount: Int
    ) -> [String] {
        var suggestions: [String] = []
        
        for insight in insights.prefix(3) {
            suggestions.append("Can you explain this for \(petName)? \"\(insight.headline)\"")
        }
        
        if suggestions.isEmpty {
            if signalCount > 0 {
                suggestions.append("What do my recent logs suggest about \(petName)?")
            } else {
                suggestions.append("What should I log to build better insights for \(petName)?")
            }
        }
        
        return Array(suggestions.prefix(3))
    }
    
    // MARK: - Dismissed Insights Persistence (UserDefaults per pet)
    
    private static func dismissedIdsKey(for petId: UUID) -> String {
        "dismissedInsights_\(petId.uuidString)"
    }
    
    private static func loadDismissedIds(for petId: UUID) -> Set<UUID> {
        let key = dismissedIdsKey(for: petId)
        guard let strings = UserDefaults.standard.stringArray(forKey: key) else { return [] }
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }
    
    private static func saveDismissedIds(_ ids: Set<UUID>, for petId: UUID) {
        let key = dismissedIdsKey(for: petId)
        UserDefaults.standard.set(ids.map { $0.uuidString }, forKey: key)
    }
}
