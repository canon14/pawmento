import SwiftUI

struct AskCoachCard: View {
    @EnvironmentObject var petStore: PetStore
    var action: () -> Void = {}
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "your pet"
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💬 Ask the Coach")
                    .font(.headlineSM)
                    .foregroundColor(.onSurface)
                Spacer()
            }
            
            Button(action: action) {
                HStack {
                    Text("How is \(petName) today?")
                        .font(.bodyMD)
                        .foregroundColor(.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.outlineVariant)
                }
                .padding(12)
                .background(Color.surfaceContainerLow)
                .cornerRadius(12)
            }
            
            HStack {
                Text("4 free questions left this month")
                    .font(.labelSM)
                    .foregroundColor(.outline)
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.surfaceBright)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.surfaceContainerLow, lineWidth: 1)
        )
        .warmShadow()
    }
}

#Preview {
    AskCoachCard()
        .environmentObject(PetStore())
        .padding()
        .background(Color.background)
}
