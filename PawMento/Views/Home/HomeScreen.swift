import SwiftUI

struct HomeScreen: View {
    @State private var selectedTab: BottomNavBar.Tab = .home
    @State private var showCoachChat = false
    @State private var showQuickLog = false
    
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
            
            // FAB (Floating Action Button)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showQuickLog = true
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.warmTan)
                            .clipShape(Circle())
                            .shadow(color: Color.warmTan.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100) // Float above bottom nav bar
                }
            }
            
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
        .sheet(isPresented: $showQuickLog) {
            QuickLogSheetView()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    HomeScreen()
}
