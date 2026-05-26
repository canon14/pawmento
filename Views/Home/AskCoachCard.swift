import SwiftUI

struct AskCoachCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💬 Ask the Coach")
                    .font(.headlineSM)
                    .foregroundColor(.onSurface)
                Spacer()
            }
            
            Button(action: {
                // Action
            }) {
                HStack {
                    Text("How was Buddy's vomiting last week?")
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
        .padding()
        .background(Color.background)
}
