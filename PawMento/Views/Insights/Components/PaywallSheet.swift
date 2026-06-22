import SwiftUI

struct PaywallSheet: View {
    @Environment(\.dismiss) var dismiss
    var insight: Insight? = nil
    var featureContext: String? = nil
    
    private var heroTitle: String {
        if insight != nil {
            return "Unlock this insight"
        } else if let feature = featureContext {
            return "Unlock \(feature)"
        } else {
            return "Upgrade to Premium"
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Contextual Hero
            VStack(spacing: 24) {
                Text(heroTitle)
                    .font(.headlineLG)
                    .foregroundColor(.ink900)
                
                if let insight = insight {
                    PatternCard(insight: insight, isPremium: true, onCardTapped: {})
                        .disabled(true) // Disable interactions inside the preview
                        .shadow(color: .ink900.opacity(0.08), radius: 15, x: 0, y: 8)
                } else {
                    // Generic beautiful premium hero
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.displayLG)
                            .foregroundColor(.primary)
                            .shadow(color: .primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("PawMento\nPremium")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.ink900)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.surface0)
                            .shadow(color: .ink900.opacity(0.05), radius: 20, x: 0, y: 10)
                    )
                }
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                if insight == nil {
                    Text("Unlock Everything")
                        .font(.headlineMD)
                } else {
                    Text("PawMento Premium")
                        .font(.headlineMD)
                }
                
                Text("Get deep-dive AI analysis, historical benchmarks, and unlimited coaching.")
                    .font(.labelLG)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.ink900.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                // Subscribe action
                dismiss()
            }) {
                Text("Upgrade Now")
                    .font(.bodyMD)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .cornerRadius(AppRadius.md)
            }
            
            Button("Not right now") {
                dismiss()
            }
            .font(.bodySM)
            .foregroundColor(.ink900.opacity(0.6))
        }
        .padding(24)
        .background(Color.background)
    }
}
