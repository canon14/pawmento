import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var coachViewModel: CoachViewModel
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var medicationStore: MedicationStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        ZStack {
            Group {
                if authManager.isAuthenticated {
                    if authManager.hasCompletedOnboarding {
                        HomeScreen()
                    } else {
                        OnboardingCarouselView()
                    }
                } else {
                    LoginScreen()
                }
            }
            .animation(.default, value: authManager.isAuthenticated)
            .animation(.default, value: authManager.hasCompletedOnboarding)
            .task {
                await authManager.checkSession()
            }
            .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
                if newValue {
                    Task {
                        await authManager.checkOnboardingState()
                        await subscriptionManager.loadProducts()
                        if let ownerId = await authManager.getCurrentUserId() {
                            await coachViewModel.initializeQuotaAndSubscription(ownerId: ownerId)
                        }
                        await petStore.fetchPets()
                        await ReminderStore.shared.fetchReminders()
                        if !petStore.pets.isEmpty {
                            await authManager.completeOnboarding()
                        }
                    }
                } else if oldValue == true && newValue == false {
                    petStore.reset()
                    coachViewModel.reset()
                    logStore.reset()
                    medicationStore.reset()
                    ReminderStore.shared.reset()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .subscriptionEntitlementsDidChange)) { _ in
                Task {
                    if let ownerId = await authManager.getCurrentUserId() {
                        await coachViewModel.initializeQuotaAndSubscription(ownerId: ownerId)
                    }
                }
            }
            
            ToastView()
        }
    }
}

#Preview {
    RootView()
}
