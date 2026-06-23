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
                                MessageBubbleView(message: message, showTimestamp: showTimestamp)
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
                    topBar
                }
                .safeAreaInset(edge: .bottom) {
                    ComposerView(
                        text: $inputText,
                        freeQuestionsRemaining: $viewModel.freeQuestionsRemaining,
                        petName: petName,
                        onCameraTap: {
                            viewModel.showPremiumWall = true
                        }
                    ) {
                        send(inputText)
                    }
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
        // Premium Wall — fully redesigned
        .sheet(isPresented: $viewModel.showPremiumWall) {
            premiumPaywallSheet
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
    }
    
    // MARK: - Welcome Hero (empty state)
    
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
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Premium Paywall Sheet
    
    private var premiumPaywallSheet: some View {
        VStack(spacing: 0) {
            // Decorative header glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primary.opacity(0.2), Color.primary.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Coach Pro")
                        .font(.headlineLG)
                        .foregroundColor(.primaryText)
                }
            }
            .padding(.top, 32)
            
            VStack(spacing: 8) {
                Text("\(petName) and I have so much more to talk about")
                    .font(.headlineSM)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primaryText)
                
                Text("Unlock unlimited coaching, photo analysis, and personalized health insights")
                    .font(.bodyMD)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            
            // Feature list
            VStack(alignment: .leading, spacing: 14) {
                premiumFeatureRow(icon: "infinity", text: "Unlimited questions every month")
                premiumFeatureRow(icon: "camera.fill", text: "Photo-based health checks")
                premiumFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Personalized trend insights")
                premiumFeatureRow(icon: "bell.badge", text: "Proactive health alerts")
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            
            Spacer()
            
            // CTA
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.showPremiumWall = false
                }) {
                    VStack(spacing: 2) {
                        Text("Start 7-day free trial")
                            .font(.headlineSM)
                        Text("then $9.99/month")
                            .font(.labelSM)
                            .opacity(0.7)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.primary, Color.primary.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.input))
                    .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: {
                    viewModel.showPremiumWall = false
                }) {
                    Text("Maybe later")
                        .font(.labelMD)
                        .foregroundColor(.tertiaryText)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }
    
    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 36, height: 36)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.bodyMD)
                .foregroundColor(.primaryText)
        }
    }
    
    // MARK: - Top Bar
    
    @State private var showWipeConfirmation = false
    
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
                HStack(spacing: 4) {
                    let emoji: String = {
                        guard let pet = petStore.activePet else { return "🐾" }
                        switch pet.species {
                        case .dog: return "🐶"
                        case .cat: return "🐱"
                        case .rabbit: return "🐰"
                        case .other: return "🐾"
                        }
                    }()
                    Text("\(emoji) \(petName)")
                        .font(.labelSM)
                        .foregroundColor(.secondaryText)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
            
            Menu {
                Button(role: .destructive, action: {
                    showWipeConfirmation = true
                }) {
                    Label("New Conversation", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainer.opacity(0.5))
                    .clipShape(Circle())
            }
            .confirmationDialog("Start New Conversation?", isPresented: $showWipeConfirmation, titleVisibility: .visible) {
                Button("Wipe History", role: .destructive) {
                    withAnimation {
                        viewModel.messages.removeAll()
                        setInitialQuickReplies()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently clear your conversation history.")
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
    
    private func send(_ text: String) {
        let textToSend = text
        inputText = ""
        let activePet = petStore.activePet
        Task {
            let ownerId = await authManager.getCurrentUserId()
            await viewModel.sendMessage(textToSend, pet: activePet, ownerId: ownerId)
        }
    }
    
    private func setInitialQuickReplies() {
        viewModel.quickReplies = [
            "Is \(petName)'s weight healthy?",
            "What should I feed \(petName)?",
            "How often should I walk them?"
        ]
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

#Preview {
    CoachChatView()
        .environmentObject(PetStore())
}
