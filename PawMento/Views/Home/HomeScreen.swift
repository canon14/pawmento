import SwiftUI

struct HomeScreen: View {
    @State private var selectedTab: BottomNavBar.Tab = .home
    @State private var showCoachChat = false
    @State private var showQuickLog = false
    @State private var showAddPetSheet = false
    @State private var showInsights = false
    
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content ScrollView
            if selectedTab == .pet {
                PetProfileScreen()
                    .environmentObject(petStore)
                    .environmentObject(logStore)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header (Sticky on top conceptually, but scrolls here)
                        TopHeaderView()
                        
                        VStack(spacing: 16) {
                            PetSelectorCard(onAddPet: { showAddPetSheet = true })
                            
                            WellnessScoreHero()

                            PatternAlertCard(action: {
                                showInsights = true
                            })
                            
                            TodayLogGrid(onLogAction: {
                                showQuickLog = true
                            })
                            
                            AskCoachCard(action: {
                                showCoachChat = true
                            })
                            
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
            }
            
            // Bottom Navigation
            VStack {
                Spacer()
                BottomNavBar(selectedTab: $selectedTab)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .coach {
                showCoachChat = true
            } else if newValue == .log {
                showQuickLog = true
            }
        }
        .fullScreenCover(isPresented: $showCoachChat, onDismiss: {
            if selectedTab == .coach {
                selectedTab = .home
            }
        }) {
            CoachChatView()
        }
        .sheet(isPresented: $showQuickLog, onDismiss: {
            if selectedTab == .log {
                selectedTab = .home
            }
        }) {
            QuickLogSheetView()
                .presentationDetents([.fraction(0.75), .large])
                .presentationCornerRadius(28)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showInsights) {
            InsightsScreen()
        }
        .sheet(isPresented: $showAddPetSheet) {
            AddPetSheet()
        }
        .onChange(of: petStore.activePet?.id) { _, newPetId in
            if let petId = newPetId {
                Task {
                    await logStore.fetchLogs(for: petId)
                }
            }
        }
    }
}

#Preview {
    HomeScreen()
}
