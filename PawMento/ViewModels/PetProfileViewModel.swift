import Foundation
import Combine

@MainActor
class PetProfileViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var aiInsight: String? = nil
    @Published var isGeneratingInsight: Bool = false
    
    // Extracted Mock Data for Care Team and Meds
    
    @Published var medications: [Medication] = []
    
    @Published var wellnessScore: Int = 0
    @Published var scoreTrend: String = "Trending →"
    @Published var scoreDelta: String = "Calculating..."
    // Fix S11: Track previous score for session-local delta
    private var previousScore: Int?
    
    // Fix S13: Accept forceRefresh parameter to bypass insight caching
    func refreshProfile(for pet: Pet, logs: [LogEntry], fetchedMedications: [Medication], forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        
        self.medications = fetchedMedications
        
        let result = WellnessCalculator.calculateScore(logs: logs, medications: fetchedMedications)
        
        // Fix W1: Use data confidence to gate score display
        if result.confidence == .insufficient {
            scoreTrend = "Need more logs"
            scoreDelta = "Gathering data"
        } else if let oldScore = previousScore {
            let delta = result.score - oldScore
            if delta > 0 {
                scoreTrend = "Trending ↗"
                scoreDelta = "+\(delta) since last check"
            } else if delta < 0 {
                scoreTrend = "Trending ↘"
                scoreDelta = "\(delta) since last check"
            } else {
                scoreTrend = "Trending →"
                scoreDelta = "Stable"
            }
        } else {
            // First calculation this session — no prior baseline to compare
            if result.score >= 80 {
                scoreTrend = "Trending ↗"
            } else if result.score >= 60 {
                scoreTrend = "Trending →"
            } else {
                scoreTrend = "Trending ↘"
            }
            scoreDelta = "Gathering data"
        }
        
        previousScore = result.score
        self.wellnessScore = result.score
        
        // Fix S13: Generate AI Insight — support forceRefresh to bypass nil-guard and cache
        if aiInsight == nil || forceRefresh {
            await generateInsight(for: pet, logs: logs, forceRefresh: forceRefresh)
        }
    }
    
    // Fix S13: Added forceRefresh parameter to bypass 24h cache
    func generateInsight(for pet: Pet, logs: [LogEntry], forceRefresh: Bool = false) async {
        let cacheKey = "ai_insight_\(pet.id.uuidString)"
        let cacheDateKey = "ai_insight_date_\(pet.id.uuidString)"
        
        // 1. Check cache (24 hours) — skip if forceRefresh
        if !forceRefresh,
           let lastDate = UserDefaults.standard.object(forKey: cacheDateKey) as? Date,
           let lastInsight = UserDefaults.standard.string(forKey: cacheKey),
           Date().timeIntervalSince(lastDate) < 24 * 3600 {
            self.aiInsight = lastInsight
            return
        }
        
        // 2. Pattern Detector Pre-filter
        let recent24hLogs = logs.filter { $0.recordedAt > Date().addingTimeInterval(-24 * 3600) }
        let hasSymptoms = recent24hLogs.contains { $0.category == .symptom }
        
        if recent24hLogs.isEmpty || (!hasSymptoms && recent24hLogs.count < 3) {
            // No significant patterns to analyze today
            self.aiInsight = "\(pet.name) is having a steady day. Log more activities or symptoms to trigger an AI pattern analysis!"
            return
        }
        
        isGeneratingInsight = true
        defer { isGeneratingInsight = false }
        
        // Fix S13: Sort logs by recordedAt descending before prefix(10) so context is truly most-recent
        let sortedLogs = logs.sorted { $0.recordedAt > $1.recordedAt }
        let recentLogsString = sortedLogs.prefix(10).map { "\($0.category.rawValue): \($0.note ?? "")" }.joined(separator: ", ")
        let prompt = """
        You are an expert AI vet coach. Briefly analyze the recent logs for \(pet.name) and provide a 1-2 sentence reassuring or observational insight. Do not prescribe.
        Recent logs: \(recentLogsString.isEmpty ? "None" : recentLogsString)
        """
        
        let messages = [["role": "user", "content": prompt]]
        
        do {
            let stream = AICoachClient.shared.streamAdvice(messages: messages)
            var fullInsight = ""
            for try await token in stream {
                fullInsight += token
                self.aiInsight = fullInsight // Update UI incrementally
            }
            
            // Cache successful result
            UserDefaults.standard.set(fullInsight, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheDateKey)
            
        } catch {
            // Fix S12: Replace hardcoded "Buddy" with pet.name
            self.aiInsight = "I lost connection while trying to analyze \(pet.name)'s data. Tap to retry."
        }
    }
}


