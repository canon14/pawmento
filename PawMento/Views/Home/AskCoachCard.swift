import SwiftUI

struct AskCoachCard: View {
    @EnvironmentObject var petStore: PetStore
    var action: () -> Void = {}
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "your pet"
        
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.primary)
                    Text("Ask the Coach")
                        .font(.headlineSM)
                        .foregroundColor(.onSurface)
                    Spacer()
                }
            
                // The whole card is the button now, but this visual input box remains to invite tapping
                HStack {
                    Text("How is \(petName) today?")
                        .font(.bodyMD)
                        .foregroundColor(.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .padding(12)
                .background(Color.surfaceContainerLowest)
                .cornerRadius(AppRadius.input)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.input)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
            
                HStack {
                    Text("4 free questions left this month")
                        .font(.labelSM)
                        .foregroundColor(.onSurfaceVariant)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(
                LinearGradient(colors: [Color.primaryContainer.opacity(0.4), Color.surfaceBright], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .warmShadow()
        }
        .buttonStyle(SquishyCardStyle())
    }
}

#Preview {
    AskCoachCard()
        .environmentObject(PetStore())
        .padding()
        .background(Color.background)
}
