import SwiftUI

struct AskCoachCard: View {
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var coachViewModel: CoachViewModel
    var action: () -> Void = {}
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "your pet"
        
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Icon + Title
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Ask the Coach")
                        .font(.headlineSM)
                        .foregroundColor(.onSurface)
                }
                
                // Fake input prompt
                HStack(spacing: 8) {
                    Text("How is \(petName) today?")
                        .font(.bodySM)
                        .foregroundColor(.onSurfaceVariant)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.surfaceContainerLowest)
                .cornerRadius(AppRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
                
                Spacer(minLength: 0)
                
                // Usage badge — hidden for premium/unlimited plans
                if !coachViewModel.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 9))
                        Text("\(coachViewModel.freeQuestionsRemaining) free question\(coachViewModel.freeQuestionsRemaining == 1 ? "" : "s") left")
                            .font(.labelSM)
                    }
                    .foregroundColor(.onSurfaceVariant)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 170)
            .background(
                LinearGradient(
                    colors: [Color.primaryContainer.opacity(0.35), Color.surfaceBright],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .warmShadow()
        }
        .buttonStyle(SquishyCardStyle())
    }
}

#Preview {
    AskCoachCard()
        .frame(width: 260)
        .environmentObject(PetStore())
        .padding()
        .background(Color.background)
}
