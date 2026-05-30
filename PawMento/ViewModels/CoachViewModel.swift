import Foundation
import Combine
import SwiftUI

@MainActor
class CoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var freeQuestionsRemaining: Int = 5
    @Published var showPremiumWall: Bool = false
    
    // Quick Replies context
    @Published var quickReplies: [String] = []
    
    // Send a message and stream the response
    func sendMessage(_ text: String, petId: UUID?) async {
        guard freeQuestionsRemaining > 0 else {
            showPremiumWall = true
            return
        }
        
        let userMessage = ChatMessage(role: .user, content: text, petId: petId)
        messages.append(userMessage)
        quickReplies.removeAll()
        
        // 1. Safety Check (Regex before LLM runs in <50ms)
        if SafetyClassifier.isEmergency(message: text) {
            let emergencyResponse = ChatMessage(role: .assistant, content: "This sounds urgent.\nGet to an emergency vet now.", isEmergency: true, petId: petId)
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
        let initialAssistantMessage = ChatMessage(id: assistantMessageId, role: .assistant, content: "", petId: petId)
        messages.append(initialAssistantMessage)
        
        do {
            let stream = AICoachClient.shared.streamAdvice(messages: recentMessages)
            for try await token in stream {
                isTyping = false
                if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                    messages[index].content += token
                }
            }
            
            // 5. Post-Stream Premium Gating (Gate 2: Coach Warning)
            if freeQuestionsRemaining == 2 {
                let warningMessage = ChatMessage(
                    role: .assistant,
                    content: "Just so you know — you've got 2 free questions left this month.\nIf you want unlimited, I'd love to keep helping."
                )
                messages.append(warningMessage)
                quickReplies = ["See Premium", "Got it"]
            }
            
            // TODO: Step 4 Supabase saving. Here we would insert `userMessage` and `messages[index]` into `public.chat_messages`
            
        } catch {
            isTyping = false
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                if error.localizedDescription.contains("API Error") {
                    messages[index].content = "\(error.localizedDescription)\n\n(Tip: Your $5 deposit may take a little longer to unlock Claude 3 access on Anthropic's servers.)"
                } else {
                    messages[index].content = "I lost connection — please tap to retry."
                }
            }
        }
    }
}
