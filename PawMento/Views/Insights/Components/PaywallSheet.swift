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
        VStack(spacing: 0) {
            // Decorative header glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primary.opacity(0.15), Color.primary.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                if insight != nil {
                    // Show a mini preview of the locked insight
                    VStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.primary)
                        Text(heroTitle)
                            .font(.headlineLG)
                            .foregroundColor(.primaryText)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.primary)
                        Text("PawMento Premium")
                            .font(.headlineLG)
                            .foregroundColor(.primaryText)
                    }
                }
            }
            .padding(.top, 32)
            
            // Subtitle
            Text("Get deep-dive AI analysis, historical benchmarks, and unlimited coaching.")
                .font(.bodyMD)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 12)
            
            // Feature list
            VStack(alignment: .leading, spacing: 14) {
                premiumFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Deep-dive pattern analysis")
                premiumFeatureRow(icon: "dog.fill", text: "Breed health benchmarks")
                premiumFeatureRow(icon: "infinity", text: "Unlimited AI coaching")
                premiumFeatureRow(icon: "bell.badge", text: "Proactive health alerts")
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            
            // Contextual preview
            if let insight = insight {
                PatternCard(insight: insight, isPremium: true, onCardTapped: {})
                    .disabled(true)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .shadow(color: Color.primary.opacity(0.08), radius: 12, x: 0, y: 4)
            }
            
            Spacer()
            
            // CTA
            VStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    VStack(spacing: 2) {
                        Text("Start 7-day free trial")
                            .font(.headlineSM)
                        Text("then $9.99/month")
                            .font(.labelSM)
                            .opacity(0.7)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.primary, Color.primary.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.input))
                    .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button("Not right now") {
                    dismiss()
                }
                .font(.labelMD)
                .foregroundColor(.tertiaryText)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.background)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }
    
    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 36, height: 36)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.bodyMD)
                .foregroundColor(.primaryText)
        }
    }
}
