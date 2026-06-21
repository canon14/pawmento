import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var petStore: PetStore
    
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
            .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    Task {
                        await authManager.checkOnboardingState()
                        await petStore.fetchPets()
                        if !petStore.pets.isEmpty {
                            await authManager.completeOnboarding()
                        }
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
