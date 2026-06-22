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
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            topBar
            
            // Chat List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.messages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 48))
                                    .foregroundColor(.primary)
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
                                                Text(reply)
                                                    .font(.labelMD)
                                                    .foregroundColor(.primaryText)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .background(Color.surface0)
                                                    .cornerRadius(AppRadius.md)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 16)
                                }
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                let showTimestamp = shouldShowTimestamp(for: index)
                                MessageBubbleView(message: message, showTimestamp: showTimestamp)
                                    .id(message.id)
                            }
                        }
                        
                        if viewModel.isTyping {
                            HStack {
                                Text("🧑‍⚕️")
                                    .font(.headlineSM)
                                    .padding(.top, 4)
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .id("typingIndicator")
                        }
                    }
                    .padding(.vertical, 16)
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
            .background(Color.background)
            

            
            // Composer
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
        .navigationBarHidden(true)
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
                Text("Coach")
                    .font(.headlineSM)
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
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.warmCream)

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
        .background(Color.surfaceBright)
        .clipShape(BubbleShape(isUser: false))
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
