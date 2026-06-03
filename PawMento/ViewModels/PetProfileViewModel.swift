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
    
    @Published var medications: [MockMedication] = [
        MockMedication(name: "Apoquel 16mg", frequency: "Daily, 8am", streak: "14 day streak ✓"),
        MockMedication(name: "Heartgard", frequency: "Monthly", streak: "Next: Jun 12 · 12 days")
    ]
    
    @Published var wellnessScore: Int = 87
    @Published var scoreTrend: String = "Trending ↗"
    @Published var scoreDelta: String = "+4 this week"
    
    func refreshProfile(for pet: Pet, logs: [LogEntry]) async {
        isLoading = true
        defer { isLoading = false }
        
        // Compute Wellness Score purely based on recent logs (stub logic for MVP)
        let recentLogs = logs.filter { $0.recordedAt > Date().addingTimeInterval(-7*24*3600) }
        var score = 80
        if recentLogs.contains(where: { $0.category == .symptom }) {
            score -= 10
            scoreTrend = "Trending ↘"
            scoreDelta = "-10 this week"
        } else if !recentLogs.isEmpty {
            score += 7
            scoreTrend = "Trending ↗"
            scoreDelta = "+7 this week"
        } else {
            scoreTrend = "Trending →"
            scoreDelta = "Stable"
        }
        self.wellnessScore = max(0, min(100, score))
        
        // Generate AI Insight using actual LLM if needed
        if aiInsight == nil {
            await generateInsight(for: pet, logs: logs)
        }
    }
    
    func generateInsight(for pet: Pet, logs: [LogEntry]) async {
        isGeneratingInsight = true
        defer { isGeneratingInsight = false }
        
        // Prepare context
        let recentLogs = logs.prefix(10).map { "\($0.category.rawValue): \($0.note ?? "")" }.joined(separator: ", ")
        let prompt = """
        You are an expert AI vet coach. Briefly analyze the recent logs for \(pet.name) and provide a 1-2 sentence reassuring or observational insight. Do not prescribe.
        Recent logs: \(recentLogs.isEmpty ? "None" : recentLogs)
        """
        
        let messages = [["role": "user", "content": prompt]]
        
        do {
            let stream = AICoachClient.shared.streamAdvice(messages: messages)
            var fullInsight = ""
            for try await token in stream {
                fullInsight += token
                self.aiInsight = fullInsight // Update UI incrementally
            }
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

struct MockMedication: Identifiable {
    let id = UUID()
    let name: String
    let frequency: String
    let streak: String
}
