import SwiftUI

struct CoachChatView: View {
    @EnvironmentObject var viewModel: CoachViewModel
    @State private var inputText = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var authManager: AuthManager
    
    @State private var heroVisible = false
    
    private var petName: String {
        petStore.activePet?.name ?? PetStore.fallbackPetName
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 24) {
                        if viewModel.messages.isEmpty {
                            welcomeHero
                        } else {
                            Color.clear.frame(height: 10)
                            
                            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                let showTimestamp = shouldShowTimestamp(for: index)
                                MessageBubbleView(
                                    message: message,
                                    showTimestamp: showTimestamp,
                                    onRetry: message.isRetryable ? { retryFailedSend() } : nil
                                )
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            // Follow-up quick replies (shown after AI response)
                            if !viewModel.quickReplies.isEmpty {
                                quickRepliesSection
                                    .id("quickReplies")
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        
                        if viewModel.isTyping {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .padding(.trailing, 4)
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .id("typingIndicator")
                        }
                    }
                    .padding(.bottom, 10)
                }
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { hideKeyboard() }
                )
                .safeAreaInset(edge: .top) {
                    VStack(spacing: 0) {
                        topBar
                        subscriptionErrorBanner
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    composerBar
                }
                .onChange(of: viewModel.messages) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isTyping) { _, typing in
                    if typing {
                        withAnimation {
                            proxy.scrollTo("typingIndicator", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.quickReplies) { _, replies in
                    if !replies.isEmpty {
                        withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                            proxy.scrollTo("quickReplies", anchor: .bottom)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture().onEnded { value in
                if value.startLocation.x < 50 && value.translation.width > 50 {
                    dismiss()
                }
            }
        )
        .modifier(CoachPremiumWallModifier(petName: petName))
        .alert("Session Expired", isPresented: $viewModel.showAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please sign in again to continue chatting with Coach.")
        }
        .onAppear {
            Task {
                if let ownerId = await authManager.getCurrentUserId() {
                    await viewModel.fetchMessages(for: petStore.activePet?.id, ownerId: ownerId)
                    
                    await MainActor.run {
                        if viewModel.messages.isEmpty {
                            setInitialQuickReplies()
                        }
                    }
                }
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                heroVisible = true
            }
        }
        .onChange(of: petStore.activePet?.id) { _, newPetId in
            Task {
                guard let ownerId = await authManager.getCurrentUserId() else { return }
                await viewModel.fetchMessages(for: newPetId, ownerId: ownerId, forceRefresh: true)
                await MainActor.run {
                    if viewModel.messages.isEmpty {
                        setInitialQuickReplies()
                    }
                }
            }
        }
    }
    
    // MARK: - Welcome Hero (empty state)
    
    private var composerBar: some View {
        ComposerView(
            text: $inputText,
            freeQuestionsRemaining: $viewModel.freeQuestionsRemaining,
            petName: petName,
            onCameraTap: {
                viewModel.presentManualPremiumWall()
            },
            onSend: {
                send(inputText)
            },
            isSending: viewModel.isSending,
            showsQuotaCounter: viewModel.shouldEnforceFreeQuota
        )
    }
    
    @ViewBuilder
    private var subscriptionErrorBanner: some View {
        if viewModel.showSubscriptionLoadError {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.warning)
                
                Text("Couldn't refresh your plan. Your access is unchanged.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
                
                Spacer(minLength: 0)
                
                Button("Retry") {
                    Task {
                        if let ownerId = await authManager.getCurrentUserId() {
                            await viewModel.initializeQuotaAndSubscription(ownerId: ownerId)
                        }
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.warning.opacity(0.1))
        }
    }
    
    private var welcomeHero: some View {
        VStack(spacing: 20) {
            ZStack {
                // Ambient rings
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    .frame(width: 110, height: 110)
                    .scaleEffect(heroVisible ? 1.0 : 0.6)
                    .opacity(heroVisible ? 1.0 : 0.0)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primary.opacity(0.2), Color.primary.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(heroVisible ? 1.0 : 0.5)
                    .opacity(heroVisible ? 1.0 : 0.0)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.primary)
                    .scaleEffect(heroVisible ? 1.0 : 0.3)
                    .opacity(heroVisible ? 1.0 : 0.0)
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.6), value: heroVisible)
            .padding(.bottom, 4)
            
            Text("Welcome to Coach")
                .font(.headlineLG)
                .foregroundColor(.primaryText)
                .opacity(heroVisible ? 1.0 : 0.0)
                .offset(y: heroVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: heroVisible)
            
            Text("I'm here to help you understand \(petName)'s health, behavior, and daily needs.")
                .font(.bodyMD)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(heroVisible ? 1.0 : 0.0)
                .offset(y: heroVisible ? 0 : 8)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: heroVisible)
            
            if !viewModel.quickReplies.isEmpty {
                quickRepliesSection
                    .padding(.top, 16)
                    .opacity(heroVisible ? 1.0 : 0.0)
                    .offset(y: heroVisible ? 0 : 12)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: heroVisible)
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - Quick Replies (reusable for welcome + follow-up)
    
    private var quickRepliesSection: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.quickReplies, id: \.self) { reply in
                Button(action: { send(reply) }) {
                    HStack(spacing: 12) {
                        Text(reply)
                            .font(.labelMD)
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.5))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color.primaryContainer.opacity(0.25))
                    .cornerRadius(AppRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(SquishyCardStyle())
                .disabled(viewModel.isSending)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Top Bar
    
    @State private var showWipeConfirmation = false
    @State private var isWipingHistory = false
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainer.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    Text("Coach")
                        .font(.headlineSM)
                }
                
                if petStore.pets.count > 1 {
                    Menu {
                        ForEach(petStore.pets) { pet in
                            Button {
                                guard pet.id != petStore.activePet?.id else { return }
                                hideKeyboard()
                                inputText = ""
                                petStore.activePet = pet
                            } label: {
                                if pet.id == petStore.activePet?.id {
                                    Label(pet.name, systemImage: "checkmark")
                                } else {
                                    Text(pet.name)
                                }
                            }
                        }
                    } label: {
                        petIdentityLabel(showsChevron: true)
                    }
                    .accessibilityLabel("Switch pet")
                    .accessibilityHint("Choose which pet Coach is talking about")
                } else {
                    petIdentityLabel(showsChevron: false)
                }
            }
            
            Spacer()
            
            Menu {
                Button(role: .destructive, action: {
                    showWipeConfirmation = true
                }) {
                    Label("New Conversation", systemImage: "trash")
                }
                .disabled(viewModel.isSending || isWipingHistory)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainer.opacity(0.5))
                    .clipShape(Circle())
            }
            .disabled(viewModel.isSending)
            .confirmationDialog("Start New Conversation?", isPresented: $showWipeConfirmation, titleVisibility: .visible) {
                Button("Wipe History", role: .destructive) {
                    Task { await wipeHistory() }
                }
                .disabled(isWipingHistory || viewModel.isSending)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete this pet's coach conversation from your account.")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .padding(.top, 6)
        .background(
            Color.surfaceContainerLowest.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.05)),
            alignment: .bottom
        )
    }
    
    // MARK: - Helpers
    
    private func petIdentityLabel(showsChevron: Bool) -> some View {
        HStack(spacing: 6) {
            petHeaderAvatar
                .frame(width: 18, height: 18)
                .clipShape(Circle())
            
            Text(petName)
                .font(.labelSM)
                .foregroundColor(.secondaryText)
                .lineLimit(1)
            
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var petHeaderAvatar: some View {
        if let pet = petStore.activePet, let image = pet.photoImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let pet = petStore.activePet, let photoURL = pet.photoLocalURL {
            CachedAsyncImage(url: photoURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Text(speciesEmoji(for: pet))
                    .font(.system(size: 11))
            }
        } else if let pet = petStore.activePet {
            Text(speciesEmoji(for: pet))
                .font(.system(size: 11))
        } else {
            Text("🐾")
                .font(.system(size: 11))
        }
    }
    
    private func speciesEmoji(for pet: Pet) -> String {
        switch pet.species {
        case .dog: return "🐶"
        case .cat: return "🐱"
        case .rabbit: return "🐰"
        case .other: return "🐾"
        }
    }
    
    private func send(_ text: String) {
        if text == "See Premium" {
            viewModel.presentManualPremiumWall()
            return
        }
        
        guard !viewModel.isSending else { return }
        
        let textToSend = text
        inputText = ""
        let activePet = petStore.activePet
        Task {
            let ownerId = await authManager.getCurrentUserId()
            await viewModel.sendMessage(textToSend, pet: activePet, ownerId: ownerId)
        }
    }
    
    private func retryFailedSend() {
        guard !viewModel.isSending else { return }
        let activePet = petStore.activePet
        Task {
            let ownerId = await authManager.getCurrentUserId()
            await viewModel.retryLastFailedSend(pet: activePet, ownerId: ownerId)
        }
    }
    
    private func setInitialQuickReplies() {
        viewModel.quickReplies = [
            "Is \(petName)'s weight healthy?",
            "What should I feed \(petName)?",
            "How often should I walk them?"
        ]
    }
    
    private func wipeHistory() async {
        guard !viewModel.isSending else { return }
        guard let petId = petStore.activePet?.id else { return }
        guard !isWipingHistory else { return }
        isWipingHistory = true
        defer { isWipingHistory = false }
        
        guard let ownerId = await authManager.getCurrentUserId() else {
            ToastManager.shared.show("Sign in again to clear history.", duration: 4.0)
            return
        }
        
        do {
            try await viewModel.wipeConversationHistory(for: petId, ownerId: ownerId)
            withAnimation {
                setInitialQuickReplies()
            }
            ToastManager.shared.show("Conversation history cleared")
        } catch {
            ToastManager.shared.show("Failed to clear history. Check your connection.", duration: 4.0)
        }
    }
    
    private func shouldShowTimestamp(for index: Int) -> Bool {
        if index == 0 { return true }
        let current = viewModel.messages[index]
        let previous = viewModel.messages[index - 1]
        return current.timestamp.timeIntervalSince(previous.timestamp) > 300
    }
}

struct TypingIndicator: View {
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0
    @State private var offset3: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().frame(width: 6, height: 6).offset(y: offset1)
            Circle().frame(width: 6, height: 6).offset(y: offset2)
            Circle().frame(width: 6, height: 6).offset(y: offset3)
        }
        .foregroundColor(.tertiaryText)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.surfaceContainerLowest)
        .clipShape(BubbleShape(isUser: false))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .onAppear {
            let baseAnimation = Animation.easeInOut(duration: 0.6).repeatForever()
            withAnimation(baseAnimation.delay(0.0)) { offset1 = -4 }
            withAnimation(baseAnimation.delay(0.2)) { offset2 = -4 }
            withAnimation(baseAnimation.delay(0.4)) { offset3 = -4 }
        }
    }
}

private struct CoachPremiumWallModifier: ViewModifier {
    @EnvironmentObject private var viewModel: CoachViewModel
    let petName: String
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.showPremiumWall, onDismiss: handleDismiss) {
                PaywallSheet(
                    featureContext: "Unlimited Coaching",
                    trigger: viewModel.paywallTrigger,
                    petName: petName
                )
            }
    }
    
    private func handleDismiss() {
        if case .coachQuotaExhausted = viewModel.paywallTrigger {
            PaywallEventGate.markCoachQuotaPaywallDismissed()
        }
    }
}

#Preview {
    CoachChatView()
        .environmentObject(PetStore())
}
