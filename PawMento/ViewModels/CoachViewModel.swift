import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
class CoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var freeQuestionsRemaining: Int = SubscriptionEntitlement.freeCoachQuestionQuotaPerPeriod
    private var hasShownLowQuotaWarning = false
    @Published var isPremium: Bool = false
    @Published var showPremiumWall: Bool = false
    @Published var showAuthError: Bool = false
    
    // Quick Replies context
    @Published var quickReplies: [String] = []
    
    // Fix S14: Track the pet whose messages are currently loaded
    private var loadedPetId: UUID?
    
    // MARK: - Quota & Subscription
    
    func initializeQuotaAndSubscription(ownerId: UUID) async {
        // 1. Fetch Subscription Status
        do {
            struct SubscriptionDTO: Codable {
                let status: String
                let plan_type: String
                let questions_used: Int
                let period_start: Date
                let current_period_end: Date?
            }
            let sub: SubscriptionDTO = try await SupabaseManager.shared.client
                .from("subscriptions")
                .select()
                .eq("user_id", value: ownerId.uuidString)
                .single()
                .execute()
                .value
            
            self.isPremium = SubscriptionEntitlement.isPremium(
                planType: sub.plan_type,
                status: sub.status,
                periodEnd: sub.current_period_end
            )
            
            if isPremium {
                self.freeQuestionsRemaining = SubscriptionEntitlement.unlimitedCoachQuota
                return
            }
            
            // 2. Initialize Quota from server (free tier)
            let now = Date()
            let thirtyDays: TimeInterval = 30 * 24 * 60 * 60
            
            if now.timeIntervalSince(sub.period_start) >= thirtyDays {
                // Period expired, reset locally and remotely
                self.freeQuestionsRemaining = SubscriptionEntitlement.freeCoachQuestionQuotaPerPeriod
                // Fix S18: Reset warning flag on actual period reset, not via didSet
                self.hasShownLowQuotaWarning = false
                
                // Reset quota on server via RPC (SECURITY DEFINER bypasses SELECT-only RLS)
                do {
                    let remaining: Int = try await SupabaseManager.shared.client
                        .rpc("reset_question_period")
                        .execute()
                        .value
                    self.freeQuestionsRemaining = remaining
                } catch {
                    print("Failed to reset quota on server: \(error)")
                }
            } else {
                // Still in period
                self.freeQuestionsRemaining = SubscriptionEntitlement.freeQuestionsRemaining(questionsUsed: sub.questions_used)
            }
            
        } catch {
            print("Failed to fetch subscription: \(error)")
            self.isPremium = false
            // Fallback for new users / errors
            self.freeQuestionsRemaining = SubscriptionEntitlement.freeCoachQuestionQuotaPerPeriod
        }
    }
    
    // Fetch previous messages for a pet
    func fetchMessages(for petId: UUID?, ownerId: UUID, forceRefresh: Bool = false) async {
        guard let petId = petId else { return }
        
        // Fix S14: Gate cache-skip on loadedPetId, not messages.last?.petId
        if !forceRefresh && !messages.isEmpty && loadedPetId == petId {
            return
        }
        
        do {
            let dtos: [ChatMessageDTO] = try await SupabaseManager.shared.client
                .from("chat_messages")
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .eq("pet_id", value: petId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            self.messages = dtos.map { $0.toMessage() }
            self.loadedPetId = petId
        } catch {
            print("Failed to fetch chat history: \(error)")
        }
    }
    
    // Send a message and stream the response
    func sendMessage(_ text: String, pet: Pet?, ownerId: UUID?) async {
        if !isPremium {
            guard freeQuestionsRemaining > 0 else {
                showPremiumWall = true
                return
            }
        }
        
        let userMessage = ChatMessage(role: .user, content: text, petId: pet?.id)
        messages.append(userMessage)
        quickReplies.removeAll()
        
        // 1. Safety Check (Regex before LLM runs in <50ms)
        if SafetyClassifier.isEmergency(message: text) {
            let emergencyResponse = ChatMessage(role: .assistant, content: "This sounds urgent.\nGet to an emergency vet now.", isEmergency: true, petId: pet?.id)
            messages.append(emergencyResponse)
            
            // Do NOT charge quota for emergencies. Safety should never be gated.
            
            if let ownerId = ownerId {
                let userDTO = userMessage.toDTO(ownerId: ownerId)
                let emergencyDTO = emergencyResponse.toDTO(ownerId: ownerId)
                
                do {
                    try await SupabaseManager.shared.client
                        .from("chat_messages")
                        .insert([userDTO, emergencyDTO])
                        .execute()
                } catch {
                    print("Failed to save emergency messages: \(error)")
                }
            }
            
            return
        }
        
        // 2. Prepare context window (last 8 messages)
        let recentMessages = Array(messages.suffix(8)).map { $0.toAPIFormat() }
        
        // 3. Stream LLM response (quota enforced and charged by ai-proxy)
        isTyping = true
        defer { isTyping = false }
        
        let assistantMessageId = UUID()
        let initialAssistantMessage = ChatMessage(id: assistantMessageId, role: .assistant, content: "", petId: pet?.id)
        messages.append(initialAssistantMessage)
        
        let systemPrompt = AICoachPrompt.buildPrompt(for: pet)
        
        do {
            let stream = AICoachClient.shared.streamAdvice(messages: recentMessages, systemPrompt: systemPrompt)
            for try await token in stream {
                if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                    messages[index].content += token
                }
            }
            
            guard let index = messages.firstIndex(where: { $0.id == assistantMessageId }) else { return }
            let assistantContent = messages[index].content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if assistantContent.isEmpty {
                messages.remove(at: index)
                if let ownerId = ownerId {
                    let userDTO = userMessage.toDTO(ownerId: ownerId)
                    _ = try? await SupabaseManager.shared.client
                        .from("chat_messages")
                        .insert(userDTO)
                        .execute()
                }
                return
            }
            
            if let ownerId = ownerId, !isPremium {
                await initializeQuotaAndSubscription(ownerId: ownerId)
            }
            
            let responseContent = assistantContent.lowercased()
            quickReplies = generateFollowUpReplies(from: responseContent, petName: pet?.name ?? "them")
            
            // Post-Stream Premium Gating (Gate 2: Coach Warning)
            if !isPremium && freeQuestionsRemaining <= 2 && freeQuestionsRemaining > 0 && !hasShownLowQuotaWarning {
                hasShownLowQuotaWarning = true
                let warningMessage = ChatMessage(
                    role: .assistant,
                    content: "Just so you know — you've got \(freeQuestionsRemaining) free questions left this month.\nIf you want unlimited, I'd love to keep helping.",
                    petId: pet?.id
                )
                messages.append(warningMessage)
                quickReplies = ["See Premium", "Got it"]
            }
            
            // Supabase saving
            if let ownerId = ownerId {
                let userDTO = userMessage.toDTO(ownerId: ownerId)
                let assistantDTO = messages[index].toDTO(ownerId: ownerId)
                let dtos: [ChatMessageDTO] = [userDTO, assistantDTO]
                
                try await SupabaseManager.shared.client
                    .from("chat_messages")
                    .insert(dtos)
                    .execute()
            }
            
        } catch {
            print("Coach stream failed: \(error)")
            
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                if let authError = error as? AICoachError, authError == .authenticationRequired {
                    messages[index].content = "Your session has expired. Please sign in again to continue."
                    showAuthError = true
                } else if let coachError = error as? AICoachError, coachError == .quotaExhausted {
                    messages.remove(at: index)
                    messages.removeAll { $0.id == userMessage.id }
                    showPremiumWall = true
                } else if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                    messages[index].content = "I lost connection — tap to retry."
                } else {
                    messages[index].content = "Something went wrong on my end. Please try again in a moment."
                }
            }
        }
    }
    
    @MainActor
    func reset() {
        messages = []
        isTyping = false
        showPremiumWall = false
        showAuthError = false
        quickReplies = []
        loadedPetId = nil
        // we deliberately keep freeQuestionsRemaining so we don't reset until initializeQuotaAndSubscription runs.
    }
    
    /// Server-first wipe: deletes chat history for the current user and pet, then clears local state.
    func wipeConversationHistory(for petId: UUID, ownerId: UUID) async throws {
        try await SupabaseManager.shared.client
            .from("chat_messages")
            .delete()
            .eq("owner_id", value: ownerId.uuidString)
            .eq("pet_id", value: petId.uuidString)
            .execute()
        
        messages = []
        quickReplies = []
        loadedPetId = petId
    }
    
    // MARK: - Follow-Up Quick Replies
    
    /// Generates 2 contextual follow-up prompts based on the AI response content.
    private func generateFollowUpReplies(from response: String, petName: String) -> [String] {
        var candidates: [String] = []
        
        // Topic detection → follow-up mapping
        if response.contains("diet") || response.contains("food") || response.contains("feed") || response.contains("nutrition") {
            candidates.append("What treats are safe for \(petName)?")
            candidates.append("How much water should \(petName) drink?")
        }
        if response.contains("walk") || response.contains("exercise") || response.contains("activity") {
            candidates.append("How long should walks be?")
            candidates.append("Is \(petName) getting enough exercise?")
        }
        if response.contains("weight") || response.contains("overweight") || response.contains("underweight") {
            candidates.append("What's a healthy weight for \(petName)?")
            candidates.append("Tips to manage \(petName)'s weight?")
        }
        if response.contains("scratch") || response.contains("itch") || response.contains("allergy") || response.contains("skin") {
            candidates.append("Could this be allergies?")
            candidates.append("Should I see a vet about this?")
        }
        if response.contains("vomit") || response.contains("diarrhea") || response.contains("stomach") {
            candidates.append("Is this an emergency?")
            candidates.append("What should I watch for?")
        }
        if response.contains("vaccine") || response.contains("shot") || response.contains("booster") {
            candidates.append("When is the next vaccine due?")
            candidates.append("What vaccines does \(petName) need?")
        }
        if response.contains("behav") || response.contains("bark") || response.contains("anxious") || response.contains("anxiety") {
            candidates.append("How can I calm \(petName)?")
            candidates.append("Is this behavior normal?")
        }
        
        // Fallback generic follow-ups
        if candidates.isEmpty {
            candidates = [
                "Tell me more about this",
                "Anything else I should know?"
            ]
        }
        
        // Return first 2 unique candidates
        return Array(candidates.prefix(2))
    }
}
