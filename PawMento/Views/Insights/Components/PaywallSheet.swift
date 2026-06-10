import SwiftUI

struct PaywallSheet: View {
    @Environment(\.dismiss) var dismiss
    let insight: Insight
    
    var body: some View {
        VStack(spacing: 32) {
            // Contextual Hero - Show the locked card unblurred briefly or at top
            VStack {
                Text("Unlock this insight")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.ink900)
                
                Text(insight.headline)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.ink900.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundColor(.sage)
            
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
