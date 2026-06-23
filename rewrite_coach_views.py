import os

coach_chat_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Coach/CoachChatView.swift"
composer_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Coach/ComposerView.swift"
bubble_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Coach/MessageBubbleView.swift"

# 1. ComposerView.swift
composer_content = """import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    @Binding var freeQuestionsRemaining: Int
    let petName: String
    let onCameraTap: () -> Void
    let onSend: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                // Attachments
                Button(action: onCameraTap) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Text Field
                TextField(placeholderText(), text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.bodyMD)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.surfaceContainerLowest)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(text.isEmpty ? 0 : 0.2), lineWidth: 1)
                    )
                
                // Send Button
                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.bodyMD.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                        .opacity(text.isEmpty ? 0.3 : 1.0)
                        .scaleEffect(text.isEmpty ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: text.isEmpty)
                }
                .disabled(text.isEmpty)
            }
            
            // Counter Pill
            Text(counterText())
                .font(.labelSM)
                .foregroundColor(counterColor())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.surfaceContainerLowest)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(counterColor().opacity(0.3), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            Color.surfaceContainerLowest.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func placeholderText() -> String {
        if freeQuestionsRemaining == 1 {
            return "Last free question — make it count 🐶"
        }
        return "Ask anything about \(petName)..."
    }
    
    private func counterText() -> String {
        if freeQuestionsRemaining > 2 {
            return "\(freeQuestionsRemaining) free this month"
        } else if freeQuestionsRemaining == 1 {
            return "Last free question"
        } else {
            return "\(freeQuestionsRemaining) left"
        }
    }
    
    private func counterColor() -> Color {
        if freeQuestionsRemaining > 2 { return .secondaryText }
        if freeQuestionsRemaining == 2 { return .warning }
        return .error
    }
}
"""

with open(composer_path, "w") as f:
    f.write(composer_content)


# 2. MessageBubbleView.swift
bubble_content = """import SwiftUI

struct BubbleShape: Shape {
    var isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        return Path(path.cgPath)
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    var showTimestamp: Bool = true
    @State private var isRevealed: Bool = false
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                userBubble
            } else {
                coachBubble
                Spacer()
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.bodyMD)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primary, Color(hex: "#7A6C5D")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(BubbleShape(isUser: true))
                .shadow(color: Color.primary.opacity(0.2), radius: 8, x: 0, y: 4)
            
            if showTimestamp || isRevealed {
                Text(message.timestamp, style: .time)
                    .font(.labelSM)
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(.leading, 48)
        .textSelection(.enabled)
        .onTapGesture {
            withAnimation { isRevealed.toggle() }
        }
    }
    
    var coachBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Sparkle Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.primary.opacity(0.2), Color.primary.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                if message.isEmergency {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("This sounds urgent")
                    }
                    .font(.headlineSM)
                    .foregroundColor(.error)
                }
                
                Text(message.content.isEmpty ? "..." : message.content)
                    .font(.bodyMD)
                    .foregroundColor(.primaryText)
                    .lineSpacing(6)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(message.isEmergency ? Color.errorTintBg : Color.surfaceContainerLowest)
            .clipShape(BubbleShape(isUser: false))
            .overlay(
                BubbleShape(isUser: false)
                    .stroke(message.isEmergency ? Color.error : Color.primary.opacity(0.05), lineWidth: message.isEmergency ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .padding(.trailing, 48)
        .textSelection(.enabled)
        .onTapGesture {
            withAnimation { isRevealed.toggle() }
        }
    }
}
"""

with open(bubble_path, "w") as f:
    f.write(bubble_content)


# 3. CoachChatView.swift
coach_chat_content = """import SwiftUI

struct CoachChatView: View {
    @EnvironmentObject var viewModel: CoachViewModel
    @State private var inputText = ""
    @Environment(\\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var authManager: AuthManager
    
    private var petName: String {
        petStore.activePet?.name ?? PetStore.fallbackPetName
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 24) {
                        if viewModel.messages.isEmpty {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color.primary.opacity(0.2), Color.primary.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 40))
                                        .foregroundColor(.primary)
                                }
                                .padding(.bottom, 8)
                                
                                Text("Welcome to Coach")
                                    .font(.headlineLG)
                                    .foregroundColor(.primaryText)
                                
                                Text("I'm here to help you understand \\(petName)'s health, behavior, and daily needs.")
                                    .font(.bodyMD)
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                if !viewModel.quickReplies.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.quickReplies, id: \\.self) { reply in
                                            Button(action: { send(reply) }) {
                                                HStack {
                                                    Text(reply)
                                                        .font(.labelMD)
                                                        .foregroundColor(.primaryText)
                                                    Spacer()
                                                    Image(systemName: "arrow.up.right")
                                                        .foregroundColor(.primary.opacity(0.6))
                                                }
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 16)
                                                .background(Color.primaryContainer.opacity(0.3))
                                                .cornerRadius(AppRadius.card)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppRadius.card)
                                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(SquishyCardStyle())
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 24)
                                }
                            }
                            .padding(.top, 60)
                        } else {
                            // Add top padding
                            Color.clear.frame(height: 20)
                            
                            ForEach(Array(viewModel.messages.enumerated()), id: \\.element.id) { index, message in
                                let showTimestamp = shouldShowTimestamp(for: index)
                                MessageBubbleView(message: message, showTimestamp: showTimestamp)
                                    .id(message.id)
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
                    .padding(.bottom, 20) // Extra padding before composer
                }
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
                .scrollDismissesKeyboard(.interactively)
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
        // Premium Wall
        .sheet(isPresented: $viewModel.showPremiumWall) {
            VStack(spacing: 24) {
                Text("\\(petName) and I have so much more to talk about")
                    .font(.headlineMD)
                    .multilineTextAlignment(.center)
                
                Text("Unlock unlimited Coach for $9.99/mo")
                    .font(.bodyLG)
                    .foregroundColor(.secondaryText)
                
                Button("Start 7-day free trial") {
                    viewModel.showPremiumWall = false
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                
                Button("Maybe later") {
                    viewModel.showPremiumWall = false
                }
                .foregroundColor(.tertiaryText)
            }
            .padding(32)
            .presentationDetents([.medium])
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
        }
    }
    
    @State private var showWipeConfirmation = false
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.headlineMD)
                    .foregroundColor(.primaryText)
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
                    Text("\\(emoji) \\(petName)")
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
                    .font(.headlineMD)
                    .foregroundColor(.primaryText)
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
        .padding(.bottom, 12)
        .padding(.top, 12) // Fallback padding for safe area
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
            "Is \\(petName)'s weight healthy?",
            "What should I feed \\(petName)?",
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
        .padding(.vertical, 12)
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
"""

with open(coach_chat_path, "w") as f:
    f.write(coach_chat_content)

print("All Coach Chat views rewritten.")
