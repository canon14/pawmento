import SwiftUI

struct PatternAlertCard: View {
    @EnvironmentObject var petStore: PetStore
    var hasAlert: Bool = false // Mocked state for now
    var action: (() -> Void)?
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "your pet"
        
        Button(action: {
            action?()
        }) {
            ZStack(alignment: .topTrailing) {
                // Background blur effect from design
                let glowColor = hasAlert ? Color.warningBorder : Color.primary
                Circle()
                    .fill(RadialGradient(colors: [glowColor.opacity(0.6), glowColor.opacity(0.0)], center: .center, startRadius: 0, endRadius: 80))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                    .offset(x: 40, y: -40)
                
                VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: hasAlert ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .foregroundColor(hasAlert ? Color.warning : Color.primary)
                        .padding(8)
                        .background(Color.surface0)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Text(hasAlert ? "Pattern noticed" : "All Clear")
                        .font(.headlineSM)
                        .foregroundColor(hasAlert ? Color.warning : Color.primary)
                }
                
                Text(hasAlert ? "\(petName)'s scratched 3 times this week." : "No anomalies detected for \(petName).")
                    .font(.bodyMD)
                    .foregroundColor(hasAlert ? Color.warning.opacity(0.8) : Color.primary.opacity(0.8))
                
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        if hasAlert {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.warning)
                        }
                        Text(hasAlert ? "See full analysis" : "View Insights")
                            .font(.labelMD)
                        Image(systemName: "chevron.right")
                            .font(.bodySM)
                    }
                    .foregroundColor(hasAlert ? Color.warning : Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(hasAlert ? Color.warning.opacity(0.3) : Color.primary.opacity(0.3), lineWidth: 1))
                }
                .padding(.top, 4)
            }
            .padding(20)
            }
            .background(
                Group {
                    if hasAlert { Color.warningBackground }
                    else { Color.primaryContainer.opacity(0.3) }
                }
                .overlay(.ultraThinMaterial.opacity(0.8))
            )
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(hasAlert ? Color.warningBorder.opacity(0.5) : Color.primary.opacity(0.2), lineWidth: 1)
            )
            .warmShadow()
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(hasAlert ? "Pattern noticed. \(petName) scratched 3 times this week." : "All Clear. No anomalies detected for \(petName).")
        }
        .buttonStyle(SquishyCardStyle())
    }
}

#Preview {
    PatternAlertCard()
        .padding()
        .background(Color.background)
}
