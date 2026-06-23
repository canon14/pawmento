import SwiftUI

struct PatternAlertCard: View {
    @EnvironmentObject var petStore: PetStore
    var hasAlert: Bool = false
    var action: (() -> Void)?
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "your pet"
        let accentColor: Color = hasAlert ? .warning : .primary
        
        Button(action: {
            action?()
        }) {
            ZStack(alignment: .topTrailing) {
                // Subtle glow accent
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.4), accentColor.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)
                    .offset(x: 30, y: -30)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Icon + Title
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: hasAlert ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        
                        Text(hasAlert ? "Pattern noticed" : "All Clear")
                            .font(.headlineSM)
                            .foregroundColor(accentColor)
                    }
                    
                    // Description
                    Text(hasAlert
                         ? "\(petName)'s scratched 3 times this week."
                         : "No anomalies for \(petName).")
                        .font(.bodySM)
                        .foregroundColor(accentColor.opacity(0.75))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                    
                    // CTA
                    HStack(spacing: 4) {
                        if hasAlert {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9))
                        }
                        Text(hasAlert ? "See analysis" : "View Insights")
                            .font(.labelSM)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 1))
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 170)
            .background(
                Group {
                    if hasAlert {
                        Color.warningBackground
                    } else {
                        Color.primaryContainer.opacity(0.25)
                    }
                }
                .overlay(.ultraThinMaterial.opacity(0.7))
            )
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .warmShadow()
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(hasAlert
                ? "Pattern noticed. \(petName) scratched 3 times this week."
                : "All Clear. No anomalies detected for \(petName).")
        }
        .buttonStyle(SquishyCardStyle())
    }
}

#Preview {
    HStack(spacing: 14) {
        PatternAlertCard()
            .frame(width: 260)
        PatternAlertCard(hasAlert: true)
            .frame(width: 260)
    }
    .padding()
    .background(Color.background)
}
