import SwiftUI

struct WelcomeCoachCard: View {
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var coachViewModel: CoachViewModel
    
    var onFollowUpTapped: (String) -> Void = { _ in }
    var onAskQuestionTapped: () -> Void = {}
    
    private var petName: String {
        petStore.activePet?.name ?? PetStore.fallbackPetName
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            
            switch coachViewModel.welcomePrimer {
            case .idle, .loading:
                loadingContent
            case .loaded(let text):
                loadedContent(text: text)
            case .failed:
                failedContent
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(AppRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .warmShadow()
    }
    
    private var headerRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text("Ask PawMento about \(petName)")
                .font(.headlineSM)
                .foregroundColor(.onSurface)
        }
    }
    
    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.surfaceContainerLowest)
                .frame(height: 14)
                .shimmer()
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.surfaceContainerLowest)
                .frame(height: 14)
                .frame(maxWidth: 280)
                .shimmer()
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.surfaceContainerLowest)
                .frame(height: 14)
                .frame(maxWidth: 220)
                .shimmer()
        }
        .padding(.top, 4)
    }
    
    private func loadedContent(text: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text)
                .font(.bodySM)
                .foregroundColor(.onSurface)
                .fixedSize(horizontal: false, vertical: true)
            
            if !coachViewModel.welcomeFollowUps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(coachViewModel.welcomeFollowUps, id: \.self) { suggestion in
                        Button {
                            onFollowUpTapped(suggestion)
                        } label: {
                            Text(suggestion)
                                .font(.labelSM)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.08))
                                .cornerRadius(AppRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            quotaLine
        }
    }
    
    private var failedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I'm ready to help with \(petName) — ask me anything about their care.")
                .font(.bodySM)
                .foregroundColor(.onSurfaceVariant)
            
            Button(action: onAskQuestionTapped) {
                HStack(spacing: 8) {
                    Text("Ask a question")
                        .font(.labelLG)
                    Image(systemName: "arrow.up.circle.fill")
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(AppRadius.sm)
            }
            .buttonStyle(.plain)
            
            quotaLine
        }
    }
    
    @ViewBuilder
    private var quotaLine: some View {
        if coachViewModel.shouldEnforceFreeQuota {
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                Text("You have \(coachViewModel.freeQuestionsRemaining) free question\(coachViewModel.freeQuestionsRemaining == 1 ? "" : "s") to get started.")
                    .font(.labelSM)
            }
            .foregroundColor(.onSurfaceVariant)
        }
    }
    
    private var cardBackground: some View {
        LinearGradient(
            colors: [Color.primaryContainer.opacity(0.35), Color.surfaceBright],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Previews

#Preview("Loading") {
    let coach = CoachViewModel()
    coach.welcomePrimer = .loading
    
    return WelcomeCoachCard()
        .environmentObject(PetStore())
        .environmentObject(coach)
        .padding()
        .background(Color.background)
}

#Preview("Loaded") {
    let petStore = PetStore()
    let coach = CoachViewModel()
    coach.welcomePrimer = .loaded("A few things to know about Luna, a 2-year-old Golden Retriever dog, right now.\n\nAt this age, regular exercise and consistent feeding help her thrive. Keep up with annual vet visits and stay current on preventatives.")
    coach.welcomeFollowUps = [
        "How much exercise does Luna need?",
        "What should I know about Luna's breed?"
    ]
    
    return WelcomeCoachCard()
        .environmentObject(petStore)
        .environmentObject(coach)
        .padding()
        .background(Color.background)
}

#Preview("Failed") {
    let coach = CoachViewModel()
    coach.welcomePrimer = .failed
    
    return WelcomeCoachCard()
        .environmentObject(PetStore())
        .environmentObject(coach)
        .padding()
        .background(Color.background)
}
