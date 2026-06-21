import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
class CoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var freeQuestionsRemaining: Int = 5
    private var hasShownLowQuotaWarning = false
    @Published var isPremium: Bool = false
    @Published var showPremiumWall: Bool = false
    
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
            }
            let sub: SubscriptionDTO = try await SupabaseManager.shared.client
                .from("subscriptions")
                .select()
                .eq("user_id", value: ownerId.uuidString)
                .single()
                .execute()
                .value
            
            self.isPremium = (sub.status == "active" || sub.plan_type == "premium")
            
            // 2. Initialize Quota from server
            let now = Date()
            let thirtyDays: TimeInterval = 30 * 24 * 60 * 60
            
            if now.timeIntervalSince(sub.period_start) >= thirtyDays {
                // Period expired, reset locally and remotely
                self.freeQuestionsRemaining = 5
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
                self.freeQuestionsRemaining = max(0, 5 - sub.questions_used)
            }
            
        } catch {
            print("Failed to fetch subscription: \(error)")
            self.isPremium = false
            // Fallback for new users / errors
            self.freeQuestionsRemaining = 5
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
        
        // 2. Fix S9: Decrement Counter via atomic RPC (serialized, not fire-and-forget)
        if !isPremium {
            do {
                let remaining: Int = try await SupabaseManager.shared.client
                    .rpc("increment_question_usage")
                    .execute()
                    .value
                self.freeQuestionsRemaining = remaining
            } catch {
                print("Failed to increment question usage: \(error)")
                // Optimistic fallback: decrement locally
                freeQuestionsRemaining = max(0, freeQuestionsRemaining - 1)
            }
        }
        
        // 3. Prepare Context Window (Last 8 messages)
        let recentMessages = Array(messages.suffix(8)).map { $0.toAPIFormat() }
        
        // 4. Stream LLM Response
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
            
            // Fix S15: On empty stream, still persist the user message so it's not lost from history
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }), messages[index].content.isEmpty {
                messages.remove(at: index)
                // Persist the user message even though the stream was empty
                if let ownerId = ownerId {
                    let userDTO = userMessage.toDTO(ownerId: ownerId)
                    _ = try? await SupabaseManager.shared.client
                        .from("chat_messages")
                        .insert(userDTO)
                        .execute()
                }
                return
            }
            
            // Post-Stream Premium Gating (Gate 2: Coach Warning)
            if !isPremium && freeQuestionsRemaining <= 2 && freeQuestionsRemaining > 0 && !hasShownLowQuotaWarning {
                hasShownLowQuotaWarning = true
                // Fix S15: Give warning message the active pet's id
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
                guard let index = messages.firstIndex(where: { $0.id == assistantMessageId }) else { return }
                let assistantDTO = messages[index].toDTO(ownerId: ownerId)
                let dtos: [ChatMessageDTO] = [userDTO, assistantDTO]
                
                try await SupabaseManager.shared.client
                    .from("chat_messages")
                    .insert(dtos)
                    .execute()
            }
            
        } catch {
            print("Coach stream failed: \(error)") // Log raw technical error for devs
            
            // Fix S9: Refund the question quota via atomic RPC (serialized)
            if !isPremium {
                do {
                    let remaining: Int = try await SupabaseManager.shared.client
                        .rpc("decrement_question_usage")
                        .execute()
                        .value
                    self.freeQuestionsRemaining = remaining
                } catch {
                    print("Failed to refund usage on server: \(error)")
                    // Optimistic fallback: refund locally
                    freeQuestionsRemaining = min(5, freeQuestionsRemaining + 1)
                }
            }
            
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
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
        quickReplies = []
        loadedPetId = nil
        // we deliberately keep freeQuestionsRemaining so we don't reset until initializeQuotaAndSubscription runs.
    }
}
