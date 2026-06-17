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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.ink900)
                
                if let insight = insight {
                    PatternCard(insight: insight, isPremium: true, onCardTapped: {})
                        .disabled(true) // Disable interactions inside the preview
                        .shadow(color: .ink900.opacity(0.08), radius: 15, x: 0, y: 8)
                } else {
                    // Generic beautiful premium hero
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.sage)
                            .shadow(color: .sage.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("PawMento\nPremium")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.ink900)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .shadow(color: .ink900.opacity(0.05), radius: 20, x: 0, y: 10)
                    )
                }
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                if insight == nil {
                    Text("Unlock Everything")
                        .font(.system(size: 20, weight: .bold))
                } else {
                    Text("PawMento Premium")
                        .font(.system(size: 20, weight: .bold))
                }
                
                Text("Get deep-dive AI analysis, historical benchmarks, and unlimited coaching.")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.ink900.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                // Subscribe action
                dismiss()
            }) {
                Text("Upgrade Now")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.sage)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            
            Button("Not right now") {
                dismiss()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.ink900.opacity(0.6))
        }
        .padding(24)
        .background(Color.background)
    }
}
