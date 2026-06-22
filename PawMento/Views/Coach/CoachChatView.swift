import SwiftUI

struct CoachChatView: View {
    @EnvironmentObject var viewModel: CoachViewModel
    @State private var inputText = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var authManager: AuthManager
    
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
                                
                                Text("I'm here to help you understand \(petName)'s health, behavior, and daily needs.")
                                    .font(.bodyMD)
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                if !viewModel.quickReplies.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.quickReplies, id: \.self) { reply in
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
                            
                            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
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
        // Premium Wall
        .sheet(isPresented: $viewModel.showPremiumWall) {
            VStack(spacing: 24) {
                Text("\(petName) and I have so much more to talk about")
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
