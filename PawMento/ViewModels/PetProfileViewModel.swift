import Foundation
import Combine

@MainActor
class PetProfileViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var aiInsight: String? = nil
    @Published var isGeneratingInsight: Bool = false
    
    // Extracted Mock Data for Care Team and Meds
    @Published var careTeam: [MockCareProvider] = [
        MockCareProvider(name: "Dr. Sarah Chen", role: "Primary vet", clinic: "Westside Animal Hospital", phone: "(555) 123-4567", distance: "0.8 mi away")
    ]
    
    @Published var medications: [Medication] = []
    
    @Published var wellnessScore: Int = 0
    @Published var scoreTrend: String = "Trending →"
    @Published var scoreDelta: String = "Calculating..."
    private var hasCalculatedInitialScore: Bool = false
    
    func refreshProfile(for pet: Pet, logs: [LogEntry], fetchedMedications: [Medication]) async {
        isLoading = true
        defer { isLoading = false }
        
        self.medications = fetchedMedications
        
        let score = WellnessCalculator.calculateScore(logs: logs, medications: fetchedMedications)
        
        if !hasCalculatedInitialScore {
            self.wellnessScore = score
            self.hasCalculatedInitialScore = true
            
            if logs.count < 3 {
                scoreTrend = "Need more logs"
                scoreDelta = "Gathering data"
            } else if score >= 80 {
                scoreTrend = "Trending ↗"
                scoreDelta = "+4 this week"
            } else if score >= 60 {
                scoreTrend = "Trending →"
                scoreDelta = "Stable"
            } else {
                scoreTrend = "Trending ↘"
                scoreDelta = "-5 this week"
            }
        } else {
            let oldScore = self.wellnessScore
            self.wellnessScore = score
            
            if logs.count < 3 {
                scoreTrend = "Need more logs"
                scoreDelta = "Gathering data"
            } else if self.wellnessScore > oldScore {
                scoreTrend = "Trending ↗"
                scoreDelta = "+\(self.wellnessScore - oldScore) this week"
            } else if self.wellnessScore < oldScore {
                scoreTrend = "Trending ↘"
                scoreDelta = "-\(oldScore - self.wellnessScore) this week"
            } else {
                scoreTrend = "Trending →"
                scoreDelta = "Stable"
            }
        }
        
        // Generate AI Insight using actual LLM if needed
        if aiInsight == nil {
            await generateInsight(for: pet, logs: logs)
        }
    }
    
    func generateInsight(for pet: Pet, logs: [LogEntry]) async {
        let cacheKey = "ai_insight_\(pet.id.uuidString)"
        let cacheDateKey = "ai_insight_date_\(pet.id.uuidString)"
        
        // 1. Check cache (24 hours)
        if let lastDate = UserDefaults.standard.object(forKey: cacheDateKey) as? Date,
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
        
        // Prepare context
        let recentLogsString = logs.prefix(10).map { "\($0.category.rawValue): \($0.note ?? "")" }.joined(separator: ", ")
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
            self.aiInsight = "I lost connection while trying to analyze Buddy's data. Tap to retry."
        }
    }
}

// Mock Models
struct MockCareProvider: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let clinic: String
    let phone: String
    let distance: String
}


