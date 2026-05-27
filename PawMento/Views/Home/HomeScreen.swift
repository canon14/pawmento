import SwiftUI

struct HomeScreen: View {
    @State private var selectedTab: BottomNavBar.Tab = .home
    @State private var showCoachChat = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content ScrollView
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header (Sticky on top conceptually, but scrolls here)
                    TopHeaderView()
                    
                    VStack(spacing: 32) {
                        PetSelectorCard()
                        
                        WellnessScoreHero()
                        
                        AskCoachCard(action: {
                            showCoachChat = true
                        })
                        
                        PatternAlertCard()
                        
                        TodayLogGrid()
                        
                        RecentActivityTimeline()
                        
                        Button("Reset Onboarding (Debug)") {
                            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                        }
                        .font(.labelMD)
                        .foregroundColor(.red)
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120) // Padding for bottom nav bar
                }
            }
            .background(Color.background)
            .edgesIgnoringSafeArea(.bottom) // Let content scroll behind nav bar
            
            // Bottom Navigation
            VStack {
                Spacer()
                BottomNavBar(selectedTab: $selectedTab)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == .coach {
                showCoachChat = true
            }
        }
        .fullScreenCover(isPresented: $showCoachChat, onDismiss: {
            if selectedTab == .coach {
                selectedTab = .home
            }
        }) {
            CoachChatView()
        }
    }
}

#Preview {
    HomeScreen()
}
