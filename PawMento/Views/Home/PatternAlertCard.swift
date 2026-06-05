import SwiftUI

struct PatternAlertCard: View {
    @EnvironmentObject var petStore: PetStore
    var hasAlert: Bool = false // Mocked state for now
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "your pet"
        
        ZStack(alignment: .topTrailing) {
            // Background blur effect from design
            Circle()
                .fill(hasAlert ? Color.warningBorder.opacity(0.3) : Color.sage.opacity(0.3))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .offset(x: 40, y: -40)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: hasAlert ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .foregroundColor(hasAlert ? Color.warning : Color.sage)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Text(hasAlert ? "Pattern noticed" : "All Clear")
                        .font(.headlineSM)
                        .foregroundColor(hasAlert ? Color.warning : Color.sage)
                }
                
                Text(hasAlert ? "\(petName)'s scratched 3 times this week." : "No anomalies detected for \(petName).")
                    .font(.bodyMD)
                    .foregroundColor(hasAlert ? Color.warning.opacity(0.8) : Color.sage.opacity(0.8))
                
                HStack {
                    Spacer()
                    Button(action: {
                        // See full analysis action
                    }) {
                        HStack(spacing: 4) {
                            if hasAlert {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                            }
                            Text(hasAlert ? "See full analysis" : "View Insights")
                                .font(.labelMD)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(hasAlert ? Color.warning : Color.sage)
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(hasAlert ? Color.warningBackground : Color.sage.opacity(0.1))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(hasAlert ? Color.warningBorder : Color.sage.opacity(0.3), lineWidth: 1)
        )
        .warmShadow()
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(hasAlert ? "Pattern noticed. \(petName) scratched 3 times this week." : "All Clear. No anomalies detected for \(petName).")
    }
}

#Preview {
    PatternAlertCard()
        .padding()
        .background(Color.background)
}
