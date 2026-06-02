import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var petStore: PetStore
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            Group {
                if authManager.isAuthenticated {
                    if hasCompletedOnboarding {
                        HomeScreen()
                    } else {
                        OnboardingCarouselView()
                    }
                } else {
                    LoginScreen()
                }
            }
            .animation(.default, value: authManager.isAuthenticated)
            .animation(.default, value: hasCompletedOnboarding)
            .task {
                await authManager.checkSession()
            }
            .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    Task {
                        await petStore.fetchPets()
                        if !petStore.pets.isEmpty {
                            hasCompletedOnboarding = true
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
