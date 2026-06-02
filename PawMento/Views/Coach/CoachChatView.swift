import SwiftUI

struct CoachChatView: View {
    @EnvironmentObject var viewModel: CoachViewModel
    @State private var inputText = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            topBar
            
            // Chat List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isTyping {
                            HStack {
                                Text("Coach is typing...")
                                    .font(.labelSM)
                                    .foregroundColor(.tertiaryText)
                                    .padding(.horizontal, 24)
                                Spacer()
                            }
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
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.background)
            
            // Action Chips
            if !viewModel.quickReplies.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.quickReplies, id: \.self) { reply in
                            Button(action: {
                                send(reply)
                            }) {
                                Text(reply)
                                    .font(.labelMD)
                                    .foregroundColor(.primaryText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(Color.background)
            }
            
            // Composer
            ComposerView(
                text: $inputText,
                freeQuestionsRemaining: $viewModel.freeQuestionsRemaining
            ) {
                send(inputText)
            }
        }
        .navigationBarHidden(true)
        // Premium Wall
        .sheet(isPresented: $viewModel.showPremiumWall) {
            VStack(spacing: 24) {
                Text("Buddy and I have so much more to talk about")
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
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Coach")
                    .font(.headlineSM)
                HStack(spacing: 4) {
                    let petName = petStore.activePet?.name ?? "your pet"
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
                        .font(.system(size: 10))
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
            
            Menu {
                Button(role: .destructive, action: {
                    withAnimation {
                        viewModel.messages.removeAll()
                    }
                }) {
                    Label("New Conversation", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.primaryText)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.warmCream)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.outline.opacity(0.12)),
            alignment: .bottom
        )
    }
    
    private func send(_ text: String) {
        let textToSend = text
        inputText = ""
        Task {
            // In production, pass the active pet's UUID
            await viewModel.sendMessage(textToSend, petId: nil)
        }
    }
}

#Preview {
    CoachChatView()
        .environmentObject(PetStore())
}
