import Foundation
import Combine
import SwiftUI
import Supabase

enum WelcomePrimerState: Equatable {
    case idle
    case loading
    case loaded(String)
    case failed
}

@MainActor
class CoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var isSending: Bool = false
    @Published var freeQuestionsRemaining: Int = SubscriptionEntitlement.freeCoachQuestionQuotaPerPeriod
    private var hasShownLowQuotaWarning = false
    @Published var isPremium: Bool = SubscriptionCache.cachedIsPremium ?? false
    @Published var subscriptionLoadState: SubscriptionLoadState = .unknown
    @Published var showSubscriptionLoadError: Bool = false
    @Published var showPremiumWall: Bool = false
    @Published var paywallTrigger: PaywallTrigger = .manual(featureContext: nil)
    @Published var showAuthError: Bool = false
    
    // Quick Replies context
    @Published var quickReplies: [String] = []
    
    // Welcome primer (first-run Home card)
    @Published var welcomePrimer: WelcomePrimerState = .idle
    @Published var welcomeFollowUps: [String] = []
    private var primerGenerationPetId: UUID?
    private static let primerCachePrefix = "welcomePrimerCache_"
    
    // Fix S14: Track the pet whose messages are currently loaded
    private var loadedPetId: UUID?
    private var fetchRequestId = UUID()
    /// Bumped whenever local messages are mutated by a send so in-flight fetches don't clobber.
    private var historyGeneration = 0
    
    // MARK: - Quota & Subscription
    
    /// Free-tier quota gates apply when the user is not premium and subscription status is known or stale.
    var shouldEnforceFreeQuota: Bool {
        guard !isPremium else { return false }
        return subscriptionLoadState == .loaded || subscriptionLoadState == .failed
    }
    
    func presentManualPremiumWall(featureContext: String? = "Unlimited Coaching") {
        paywallTrigger = .manual(featureContext: featureContext)
        showPremiumWall = true
    }
    
    func presentQuotaPaywallIfAllowed() {
        guard PaywallEventGate.shouldPresentCoachQuotaExhausted() else { return }
        paywallTrigger = .coachQuotaExhausted
        showPremiumWall = true
    }
    
    func initializeQuotaAndSubscription(ownerId: UUID, attempt: Int = 1, maxAttempts: Int = 3) async {
        do {
            let snapshot = try await SubscriptionStatusFetcher.fetch(ownerId: ownerId)
            isPremium = snapshot.isPremium
            freeQuestionsRemaining = snapshot.freeQuestionsRemaining
            if snapshot.resetLowQuotaWarning {
                hasShownLowQuotaWarning = false
            }
            subscriptionLoadState = .loaded
            showSubscriptionLoadError = false
            SubscriptionCache.save(isPremium: isPremium)
        } catch {
            print("Failed to fetch subscription (attempt \(attempt)): \(error)")
            
            if attempt < maxAttempts {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await initializeQuotaAndSubscription(ownerId: ownerId, attempt: attempt + 1, maxAttempts: maxAttempts)
                return
            }
            
            subscriptionLoadState = .failed
            showSubscriptionLoadError = true
        }
    }
    
    // MARK: - Welcome Primer (quota-exempt gift; cached per pet)
    
    func generateWelcomePrimer(for pet: Pet) async {
        if let cached = Self.loadCachedPrimer(for: pet.id) {
            welcomePrimer = .loaded(cached)
            welcomeFollowUps = Self.welcomeFollowUpSuggestions(for: pet)
            primerGenerationPetId = pet.id
            return
        }
        
        if primerGenerationPetId == pet.id {
            switch welcomePrimer {
            case .loading, .loaded:
                return
            case .idle, .failed:
                break
            }
        } else {
            welcomePrimer = .loading
            welcomeFollowUps = Self.welcomeFollowUpSuggestions(for: pet)
        }
        
        primerGenerationPetId = pet.id
        welcomePrimer = .loading
        welcomeFollowUps = Self.welcomeFollowUpSuggestions(for: pet)
        
        let systemPrompt = AICoachPrompt.profilePrimer(for: pet)
        let triggerMessage: [[String: String]] = [
            ["role": "user", "content": "Generate my profile welcome primer."]
        ]
        
        do {
            var assembled = ""
            let stream = AICoachClient.shared.streamAdvice(
                messages: triggerMessage,
                systemPrompt: systemPrompt,
                exemptQuota: true
            )
            for try await token in stream {
                assembled += token
            }
            
            let trimmed = assembled.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                welcomePrimer = .failed
                return
            }
            
            Self.saveCachedPrimer(trimmed, for: pet.id)
            welcomePrimer = .loaded(trimmed)
        } catch {
            print("Welcome primer generation failed: \(error)")
            welcomePrimer = .failed
        }
    }
    
    static func welcomeFollowUpSuggestions(for pet: Pet) -> [String] {
        let name = pet.name
        let lifeStage = petLifeStage(for: pet)
        
        switch pet.species {
        case .dog:
            switch lifeStage {
            case .puppy:
                return [
                    "What vaccines does \(name) need as a puppy?",
                    "How often should I feed \(name)?"
                ]
            case .senior:
                return [
                    "What symptoms should I watch for in senior dogs?",
                    "How can I keep \(name) comfortable?"
                ]
            case .adult:
                return [
                    "How much exercise does \(name) need?",
                    "What should I know about \(name)'s breed?"
                ]
            }
        case .cat:
            switch lifeStage {
            case .puppy:
                return [
                    "What vaccines does \(name) need as a kitten?",
                    "How do I litter-train \(name)?"
                ]
            case .senior:
                return [
                    "What should I watch for in senior cats?",
                    "How can I keep \(name) comfortable?"
                ]
            case .adult:
                return [
                    "How much should \(name) eat each day?",
                    "Is \(name) getting enough playtime?"
                ]
            }
        case .rabbit:
            return [
                "What should \(name) eat daily?",
                "How do I keep \(name)'s habitat healthy?"
            ]
        case .other:
            return [
                "What does \(name) need day to day?",
                "When should I see a vet for \(name)?"
            ]
        }
    }
    
    private enum PetLifeStage {
        case puppy
        case adult
        case senior
    }
    
    private static func petLifeStage(for pet: Pet) -> PetLifeStage {
        guard let bday = pet.birthday,
              let birthDate = calendarBirthDate(from: bday) else {
            return .adult
        }
        
        let ageYears = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
        if ageYears < 1 {
            return .puppy
        }
        
        switch pet.species {
        case .dog:
            return ageYears >= 7 ? .senior : .adult
        case .cat:
            return ageYears >= 10 ? .senior : .adult
        case .rabbit, .other:
            return ageYears >= 6 ? .senior : .adult
        }
    }
    
    private static func calendarBirthDate(from bday: DateComponents) -> Date? {
        var components = DateComponents()
        components.year = bday.year
        components.month = bday.month ?? 1
        components.day = bday.day ?? 1
        guard bday.year != nil else { return nil }
        return Calendar.current.date(from: components)
    }
    
    private static func loadCachedPrimer(for petId: UUID) -> String? {
        UserDefaults.standard.string(forKey: primerCachePrefix + petId.uuidString)
    }
    
    private static func saveCachedPrimer(_ text: String, for petId: UUID) {
        UserDefaults.standard.set(text, forKey: primerCachePrefix + petId.uuidString)
    }
    
    // Fetch previous messages for a pet
    func fetchMessages(for petId: UUID?, ownerId: UUID, forceRefresh: Bool = false) async {
        guard let petId = petId else { return }
        guard !isSending else { return }
        
        // Fix S14: Gate cache-skip on loadedPetId, not messages.last?.petId
        if !forceRefresh && !messages.isEmpty && loadedPetId == petId {
            return
        }
        
        let requestId = UUID()
        fetchRequestId = requestId
        let generationAtStart = historyGeneration
        
        do {
            let dtos: [ChatMessageDTO] = try await SupabaseManager.shared.client
                .from("chat_messages")
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .eq("pet_id", value: petId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            // Latest-wins + don't clobber an in-flight or completed send that mutated local history.
            guard fetchRequestId == requestId else { return }
            guard !isSending else { return }
            guard historyGeneration == generationAtStart else { return }
            
            self.messages = dtos.map { $0.toMessage() }
            self.loadedPetId = petId
        } catch {
            print("Failed to fetch chat history: \(error)")
        }
    }
    
    /// Sends a user message and streams the coach reply.
    ///
    /// Quota ordering (authoritative enforcement is server-side in `ai-proxy`):
    /// 1. Client pre-check — `freeQuestionsRemaining` is a UI hint only.
    /// 2. `ai-proxy` rejects the request if quota is exhausted (before Anthropic).
    /// 3. `ai-proxy` consumes one question only after a successful non-empty stream.
    /// 4. On success, this view model refreshes `freeQuestionsRemaining` from the server.
    /// User messages are persisted to Supabase before streaming; assistant messages are saved only after a successful reply.
    func sendMessage(_ text: String, pet: Pet?, ownerId: UUID?) async {
        guard !isSending else { return }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isSending = true
        defer { isSending = false }
        
        // Client-side pre-check (optimistic UI gate; ai-proxy enforces authoritatively).
        if shouldEnforceFreeQuota {
            guard freeQuestionsRemaining > 0 else {
                presentQuotaPaywallIfAllowed()
                return
            }
        }
        
        let userMessage = ChatMessage(role: .user, content: trimmed, petId: pet?.id)
        messages.append(userMessage)
        historyGeneration += 1
        quickReplies.removeAll()
        
        // 1. Safety Check (Regex before LLM runs in <50ms)
        if SafetyClassifier.isEmergency(message: trimmed) {
            let emergencyResponse = ChatMessage(role: .assistant, content: "This sounds urgent.\nGet to an emergency vet now.", isEmergency: true, petId: pet?.id)
            messages.append(emergencyResponse)
            historyGeneration += 1
            
            // Emergencies skip the LLM entirely — no ai-proxy call, no quota consumed.
            
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
            
            loadedPetId = pet?.id
            return
        }
        
        // Snapshot context before any await — fetchMessages can run concurrently on open.
        let apiMessages = Array(messages.suffix(8)).map { $0.toAPIFormat() }
        
        // Persist user message before streaming so it survives assistant failures.
        if let ownerId = ownerId {
            await CoachMessagePersistence.insert(userMessage, ownerId: ownerId)
        }
        
        // 2. Stream via ai-proxy (quota checked before Anthropic; consumed after success).
        isTyping = true
        defer { isTyping = false }
        
        let assistantMessageId = UUID()
        let initialAssistantMessage = ChatMessage(id: assistantMessageId, role: .assistant, content: "", petId: pet?.id)
        messages.append(initialAssistantMessage)
        
        let systemPrompt = AICoachPrompt.buildPrompt(for: pet)
        
        do {
            let stream = AICoachClient.shared.streamAdvice(messages: apiMessages, systemPrompt: systemPrompt)
            for try await token in stream {
                if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                    messages[index].content += token
                }
            }
            
            guard let index = messages.firstIndex(where: { $0.id == assistantMessageId }) else { return }
            let assistantContent = messages[index].content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if assistantContent.isEmpty {
                messages.remove(at: index)
                historyGeneration += 1
                // User was already persisted; remove orphan so reopen doesn't show a user-only row.
                if let ownerId = ownerId {
                    await CoachMessagePersistence.delete(id: userMessage.id, ownerId: ownerId)
                }
                let failure = ChatMessage(
                    role: .assistant,
                    content: "Something went wrong on my end. Please try again in a moment.",
                    isRetryable: true,
                    petId: pet?.id
                )
                messages.append(failure)
                historyGeneration += 1
                loadedPetId = pet?.id
                return
            }
            
            if let ownerId = ownerId, !isPremium {
                // Sync local quota display with server after ai-proxy consumed usage.
                await initializeQuotaAndSubscription(ownerId: ownerId)
            }
            
            let responseContent = assistantContent.lowercased()
            quickReplies = generateFollowUpReplies(from: responseContent, petName: pet?.name ?? "them")
            
            // Post-Stream Premium Gating (Gate 2: Coach Warning)
            if !isPremium && shouldEnforceFreeQuota && freeQuestionsRemaining <= 2 && freeQuestionsRemaining > 0 && !hasShownLowQuotaWarning {
                hasShownLowQuotaWarning = true
                let warningMessage = ChatMessage(
                    role: .assistant,
                    content: "Just so you know — you've got \(freeQuestionsRemaining) free questions left this month.\nIf you want unlimited, I'd love to keep helping.",
                    petId: pet?.id
                )
                messages.append(warningMessage)
                historyGeneration += 1
                quickReplies = ["See Premium", "Got it"]
            }
            
            // Assistant-only save — user message was persisted before the stream.
            if let ownerId = ownerId {
                await CoachMessagePersistence.insert(messages[index], ownerId: ownerId)
            }
            
            loadedPetId = pet?.id
            
        } catch {
            print("Coach stream failed: \(error)")
            
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                if let authError = error as? AICoachError, authError == .authenticationRequired {
                    messages[index].content = "Your session has expired. Please sign in again to continue."
                    showAuthError = true
                } else if let coachError = error as? AICoachError, coachError == .quotaExhausted {
                    messages.remove(at: index)
                    historyGeneration += 1
                    presentQuotaPaywallIfAllowed()
                } else if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                    messages[index].content = "I lost connection — tap to retry."
                    messages[index].isRetryable = true
                } else {
                    messages[index].content = "Something went wrong on my end. Please try again in a moment."
                    messages[index].isRetryable = true
                }
            }
            
            loadedPetId = pet?.id
        }
    }
    
    /// Retries the user message preceding the last retryable assistant error bubble.
    func retryLastFailedSend(pet: Pet?, ownerId: UUID?) async {
        guard !isSending else { return }
        guard let retryIndex = messages.lastIndex(where: { $0.role == .assistant && $0.isRetryable }) else { return }
        guard retryIndex > 0, messages[retryIndex - 1].role == .user else { return }
        
        let userText = messages[retryIndex - 1].content
        let userId = messages[retryIndex - 1].id
        
        messages.remove(at: retryIndex)
        messages.remove(at: retryIndex - 1)
        historyGeneration += 1
        
        // Orphan user may still be in DB from the failed attempt — clear before re-send.
        if let ownerId = ownerId {
            await CoachMessagePersistence.delete(id: userId, ownerId: ownerId)
        }
        
        await sendMessage(userText, pet: pet, ownerId: ownerId)
    }
    
    @MainActor
    func reset() {
        messages = []
        isTyping = false
        isSending = false
        isPremium = false
        subscriptionLoadState = .unknown
        showSubscriptionLoadError = false
        showPremiumWall = false
        paywallTrigger = .manual(featureContext: nil)
        showAuthError = false
        quickReplies = []
        welcomePrimer = .idle
        welcomeFollowUps = []
        primerGenerationPetId = nil
        loadedPetId = nil
        historyGeneration = 0
        fetchRequestId = UUID()
        SubscriptionCache.clear()
        // we deliberately keep freeQuestionsRemaining so we don't reset until initializeQuotaAndSubscription runs.
    }
    
    /// Server-first wipe: deletes chat history for the current user and pet, then clears local state.
    func wipeConversationHistory(for petId: UUID, ownerId: UUID) async throws {
        guard !isSending else { return }
        
        try await SupabaseManager.shared.client
            .from("chat_messages")
            .delete()
            .eq("owner_id", value: ownerId.uuidString)
            .eq("pet_id", value: petId.uuidString)
            .execute()
        
        messages = []
        quickReplies = []
        historyGeneration += 1
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
