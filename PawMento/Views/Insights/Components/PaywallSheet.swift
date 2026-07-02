import SwiftUI

struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var coachViewModel: CoachViewModel
    @EnvironmentObject private var authManager: AuthManager
    
    var insight: Insight? = nil
    var featureContext: String? = nil
    
    @State private var purchaseError: String?
    
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
            
            Text("Get deep-dive AI analysis, historical benchmarks, and unlimited coaching.")
                .font(.bodyMD)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 14) {
                premiumFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Deep-dive pattern analysis")
                premiumFeatureRow(icon: "dog.fill", text: "Breed health benchmarks")
                premiumFeatureRow(icon: "infinity", text: "Unlimited AI coaching")
                premiumFeatureRow(icon: "bell.badge", text: "Proactive health alerts")
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            
            if let insight = insight {
                PatternCard(insight: insight, isPremium: true, onCardTapped: {})
                    .disabled(true)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .shadow(color: Color.primary.opacity(0.08), radius: 12, x: 0, y: 4)
            }
            
            if let purchaseError {
                Text(purchaseError)
                    .font(.labelSM)
                    .foregroundColor(.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: { Task { await startPurchase() } }) {
                    VStack(spacing: 2) {
                        if subscriptionManager.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(subscriptionManager.trialCTA)
                                .font(.headlineSM)
                            Text(subscriptionManager.priceSubtitle)
                                .font(.labelSM)
                                .opacity(0.7)
                        }
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
                .disabled(subscriptionManager.isPurchasing)
                
                Button("Restore Purchases") {
                    Task { await restorePurchases() }
                }
                .font(.labelMD)
                .foregroundColor(.primary)
                .disabled(subscriptionManager.isPurchasing)
                
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
        .task {
            await subscriptionManager.loadProducts()
        }
    }
    
    private func startPurchase() async {
        purchaseError = nil
        let outcome = await subscriptionManager.purchasePro {
            await refreshEntitlements()
        }
        handleOutcome(outcome, successMessage: "Welcome to PawMento Pro!")
    }
    
    private func restorePurchases() async {
        purchaseError = nil
        let outcome = await subscriptionManager.restorePurchases {
            await refreshEntitlements()
        }
        handleOutcome(outcome, successMessage: "Subscription restored!")
    }
    
    private func refreshEntitlements() async {
        guard let ownerId = await authManager.getCurrentUserId() else { return }
        await coachViewModel.initializeQuotaAndSubscription(ownerId: ownerId)
    }
    
    private func handleOutcome(_ outcome: PurchaseOutcome, successMessage: String) {
        switch outcome {
        case .success:
            ToastManager.shared.show(successMessage)
            dismiss()
        case .cancelled:
            break
        case .failed(let message):
            purchaseError = message
            ToastManager.shared.show(message, duration: 4.0)
        }
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
