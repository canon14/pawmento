import Foundation

actor InsightEngine {
    static let shared = InsightEngine()
    
    // Fix I3: Cache with TTL and size bound
    private struct CacheEntry {
        let insights: [Insight]
        let signalCount: Int
        let generatedAt: Date
    }
    
    private var cache: [String: CacheEntry] = [:]
    
    // Fix I11: Coalesce concurrent generation for the same pet+window key.
    private var inFlightTasks: [String: Task<(insights: [Insight], signalCount: Int), Error>] = [:]
    
    /// Bumped on `clearCache(for:)` so in-flight pipelines skip stale cache writes after log mutations.
    private var cacheGenerationByPet: [UUID: Int] = [:]
    
    // Fix I3: Cache configuration
    private let cacheTTL: TimeInterval = 15 * 60 // 15 minutes
    private let maxCacheEntries = 20
    
    // Test seams (InsightEngineTests)
    private var pipelineExecutionCount = 0
    var pipelineDelayNanoseconds: UInt64 = 0
    
    private init() {}
    
    private func cacheKey(petId: UUID, window: TimeRange) -> String {
        return "\(petId.uuidString)_\(window.rawValue)"
    }
    
    func clearCache(for petId: UUID) {
        let prefix = "\(petId.uuidString)_"
        cacheGenerationByPet[petId, default: 0] += 1
        for (key, task) in inFlightTasks where key.hasPrefix(prefix) {
            task.cancel()
            inFlightTasks.removeValue(forKey: key)
        }
        cache = cache.filter { !$0.key.hasPrefix(prefix) }
    }
    
    func isCachedForTesting(petId: UUID, window: TimeRange) -> Bool {
        cache[cacheKey(petId: petId, window: window)] != nil
    }
    
    func resetForTesting(pipelineDelayNanoseconds: UInt64 = 0) {
        cache.removeAll()
        inFlightTasks.removeAll()
        cacheGenerationByPet.removeAll()
        pipelineExecutionCount = 0
        self.pipelineDelayNanoseconds = pipelineDelayNanoseconds
    }
    
    func pipelineExecutionCountForTesting() -> Int {
        pipelineExecutionCount
    }
    
    func generateInsights(for pet: Pet?, window: TimeRange, forceRefresh: Bool = false) async throws -> (insights: [Insight], signalCount: Int) {
        guard let petId = pet?.id else { return ([], 0) }
        let key = cacheKey(petId: petId, window: window)
        
        // 1. Cache check with TTL
        if !forceRefresh, let cached = cache[key] {
            // Fix I3: Check TTL — expired entries are treated as misses
            if Date().timeIntervalSince(cached.generatedAt) < cacheTTL {
                return (cached.insights, cached.signalCount)
            } else {
                cache.removeValue(forKey: key)
            }
        }
        
        // Fix I11: Await an in-flight generation instead of starting duplicate detector+LLM work.
        if let inFlight = inFlightTasks[key] {
            return try await inFlight.value
        }
        
        let task = Task<(insights: [Insight], signalCount: Int), Error> {
            try await self.runPipeline(pet: pet, window: window, key: key)
        }
        inFlightTasks[key] = task
        
        defer {
            inFlightTasks.removeValue(forKey: key)
        }
        
        return try await task.value
    }
    
    private func runPipeline(
        pet: Pet?,
        window: TimeRange,
        key: String
    ) async throws -> (insights: [Insight], signalCount: Int) {
        pipelineExecutionCount += 1
        
        if pipelineDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: pipelineDelayNanoseconds)
        }
        
        guard let petId = pet?.id else { return ([], 0) }
        let generationAtStart = cacheGenerationByPet[petId] ?? 0
        
        // 2. Load signals
        let signals = try await SignalLoader.load(petId: petId, window: window)
        
        // 3. Run on-device detectors in parallel
        async let correlations = CorrelationDetector.detect(signals)
        async let temporal = TemporalPatternDetector.detect(signals)
        async let trends = TrendDetector.detect(signals)
        async let positives = MilestoneDetector.detect(signals)
        
        // 4. Collect & Deduplicate
        let allCandidates = await [correlations, temporal, trends, positives].flatMap { $0 }
        
        // Separate rule-based (no LLM needed) from LLM-scored
        let ruleBasedCandidates = allCandidates.filter { $0.isRuleBased }
        let llmCandidates = allCandidates.filter { !$0.isRuleBased }
        
        var finalInsights: [Insight] = []
        
        // Convert rule-based directly — derive tier from candidate type
        for rb in ruleBasedCandidates {
            let insight = Insight(
                id: UUID(),
                type: rb.type,
                tier: tierForType(rb.type),
                headline: rb.precomputedHeadline ?? "Positive Update",
                narrative: rb.precomputedNarrative ?? "",
                confidence: 1.0,
                evidenceCount: rb.evidenceCount,
                visualization: rb.precomputedVisualization ?? VisualizationData(dataPoints: [1], labels: nil, chartType: "streak"),
                actions: [InsightAction(title: "Share streak ›", isPrimary: true)],
                generatedAt: Date()
            )
            finalInsights.append(insight)
        }
        
        // 5. Score with LLM Narrator
        if !llmCandidates.isEmpty {
            let speciesStr = pet != nil ? String(describing: pet!.species) : "pet"
            // Fix I9: Replace hardcoded "Buddy" with neutral "your pet"
            let petContext = "Pet is a \(speciesStr) named \(pet?.name ?? "your pet")."
            // The narrator guarantees insights are returned (either via LLM or a local fallback).
            let scored = await InsightNarrator.scoreAndNarrate(candidates: llmCandidates, petContext: petContext)
            finalInsights.append(contentsOf: scored)
        }
        
        // 6. Sort and Cache
        finalInsights.sort { $0.tier.priority < $1.tier.priority }
        let topInsights = Array(finalInsights.prefix(8))
        
        // Fix I3: Enforce cache size bound — evict oldest entries if over limit
        if cache.count >= maxCacheEntries {
            let sorted = cache.sorted { $0.value.generatedAt < $1.value.generatedAt }
            let toRemove = cache.count - maxCacheEntries + 1
            for entry in sorted.prefix(toRemove) {
                cache.removeValue(forKey: entry.key)
            }
        }
        
        if generationAtStart == (cacheGenerationByPet[petId] ?? 0) {
            cache[key] = CacheEntry(insights: topInsights, signalCount: signals.count, generatedAt: Date())
        }
        
        return (topInsights, signals.count)
    }
    
    // MARK: - Tier Mapping
    
    /// Derives the appropriate ConfidenceTier from an InsightType.
    /// Rule-based candidates use this instead of hardcoding .positive.
    private func tierForType(_ type: InsightType) -> ConfidenceTier {
        switch type {
        case .correlation: return .strong
        case .temporal:    return .moderate
        case .trend:       return .moderate
        case .positive:    return .positive
        }
    }
}
