import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
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
            
            ToastView()
        }
    }
}

#Preview {
    RootView()
}
