import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
class CoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var freeQuestionsRemaining: Int = 5
    @Published var showPremiumWall: Bool = false
    
    // Quick Replies context
    @Published var quickReplies: [String] = []
    
    // Fetch previous messages for a pet
    func fetchMessages(for petId: UUID?, ownerId: UUID) async {
        guard let petId = petId else { return }
        
        // Prevent overwriting active chat if we already loaded it for this pet
        if !messages.isEmpty && messages.last?.petId == petId {
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
        } catch {
            print("Failed to fetch chat history: \(error)")
        }
    }
    
    // Send a message and stream the response
    func sendMessage(_ text: String, pet: Pet?, ownerId: UUID?) async {
        guard freeQuestionsRemaining > 0 else {
            showPremiumWall = true
            return
        }
        
        let userMessage = ChatMessage(role: .user, content: text, petId: pet?.id)
        messages.append(userMessage)
        quickReplies.removeAll()
        
        // 1. Safety Check (Regex before LLM runs in <50ms)
        if SafetyClassifier.isEmergency(message: text) {
            let emergencyResponse = ChatMessage(role: .assistant, content: "This sounds urgent.\nGet to an emergency vet now.", isEmergency: true, petId: pet?.id)
            messages.append(emergencyResponse)
            return
        }
        
        // 2. Decrement Counter (Gate 1)
        freeQuestionsRemaining -= 1
        
        // 3. Prepare Context Window (Last 8 messages)
        let recentMessages = Array(messages.suffix(8)).map { $0.toAPIFormat() }
        
        // 4. Stream LLM Response
        isTyping = true
        let assistantMessageId = UUID()
        let initialAssistantMessage = ChatMessage(id: assistantMessageId, role: .assistant, content: "", petId: pet?.id)
        messages.append(initialAssistantMessage)
        
        let systemPrompt = AICoachPrompt.buildPrompt(for: pet)
        
        do {
            let stream = AICoachClient.shared.streamAdvice(messages: recentMessages, systemPrompt: systemPrompt)
            for try await token in stream {
                isTyping = false
                if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                    messages[index].content += token
                }
            }
            
            // Post-Stream Premium Gating (Gate 2: Coach Warning)
            if freeQuestionsRemaining == 2 {
                let warningMessage = ChatMessage(
                    role: .assistant,
                    content: "Just so you know — you've got 2 free questions left this month.\nIf you want unlimited, I'd love to keep helping."
                )
                messages.append(warningMessage)
                quickReplies = ["See Premium", "Got it"]
            }
            
            // Supabase saving
            if let ownerId = ownerId {
                let userDTO = userMessage.toDTO(ownerId: ownerId)
                let assistantDTO = messages[messages.firstIndex(where: { $0.id == assistantMessageId })!].toDTO(ownerId: ownerId)
                let dtos: [ChatMessageDTO] = [userDTO, assistantDTO]
                
                try await SupabaseManager.shared.client
                    .from("chat_messages")
                    .insert(dtos)
                    .execute()
            }
            
        } catch {
            isTyping = false
            print("Coach stream failed: \(error)") // Log raw technical error for devs
            
            // Refund the question quota if we failed
            freeQuestionsRemaining += 1
            
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                    messages[index].content = "I lost connection — tap to retry."
                } else {
                    messages[index].content = "Something went wrong on my end. Please try again in a moment."
                }
            }
        }
    }
}
