import SwiftUI
import StoreKit

struct SubscriptionManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var coachViewModel: CoachViewModel
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var actionError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.primary)
                        Text("PawMento Pro")
                            .font(.headlineLG)
                            .foregroundColor(.primaryText)
                        Text("Active subscription")
                            .font(.bodySM)
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        planDetailRow(icon: "chart.line.uptrend.xyaxis", text: "Deep-dive pattern analysis")
                        planDetailRow(icon: "dog.fill", text: "Breed health benchmarks")
                        planDetailRow(icon: "infinity", text: "Unlimited AI coaching")
                        planDetailRow(icon: "bell.badge", text: "Proactive health alerts")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    
                    if let actionError {
                        Text(actionError)
                            .font(.labelSM)
                            .foregroundColor(.error)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: { Task { await openManageSubscriptions() } }) {
                            Text("Manage or Cancel in App Store")
                                .font(.headlineSM)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color.primary, Color.primary.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.input))
                        }
                        
                        Button("Restore Purchases") {
                            Task { await restorePurchases() }
                        }
                        .font(.labelMD)
                        .foregroundColor(.primary)
                        .disabled(subscriptionManager.isPurchasing)
                        
                        if subscriptionManager.isPurchasing {
                            ProgressView()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color.background)
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }
    
    private func openManageSubscriptions() async {
        actionError = nil
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            do {
                try await AppStore.showManageSubscriptions(in: scene)
                return
            } catch {
                print("AppStore.showManageSubscriptions failed: \(error)")
            }
        }
        openSubscriptionsURL()
    }
    
    private func openSubscriptionsURL() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }
    
    private func restorePurchases() async {
        actionError = nil
        let outcome = await subscriptionManager.restorePurchases {
            await refreshEntitlements()
        }
        switch outcome {
        case .success:
            ToastManager.shared.show("Subscription restored!")
        case .cancelled:
            break
        case .failed(let message):
            actionError = message
            ToastManager.shared.show(message, duration: 4.0)
        }
    }
    
    private func refreshEntitlements() async {
        guard let ownerId = await authManager.getCurrentUserId() else { return }
        await coachViewModel.initializeQuotaAndSubscription(ownerId: ownerId)
    }
    
    private func planDetailRow(icon: String, text: String) -> some View {
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
