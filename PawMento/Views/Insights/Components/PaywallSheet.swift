import SwiftUI

struct PaywallSheet: View {
    @Environment(\.dismiss) var dismiss
    let insight: Insight
    
    var body: some View {
        VStack(spacing: 32) {
            // Contextual Hero - Show the locked card unblurred
            VStack(spacing: 24) {
                Text("Unlock this insight")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.ink900)
                
                PatternCard(insight: insight, isPremium: true, onCardTapped: {})
                    .disabled(true) // Disable interactions inside the preview
                    .shadow(color: .ink900.opacity(0.08), radius: 15, x: 0, y: 8)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                Text("PawMento Premium")
                    .font(.system(size: 20, weight: .bold))
                
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
