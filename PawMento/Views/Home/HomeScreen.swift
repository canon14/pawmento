import SwiftUI
import Supabase

struct HomeScreen: View {
    @State private var selectedTab: BottomNavBar.Tab = .home
    @State private var showCoachChat = false
    @State private var showQuickLog = false
    @State private var showAddPetSheet = false
    @State private var showInsights = false
    
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @StateObject private var reminderStore = ReminderStore.shared
    
    @State private var showCreateReminder = false
    @State private var reminderToEdit: Reminder? = nil
    @State private var showFullTimeline = false
    
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
                            
                            upNextRemindersSection
                            WellnessScoreHero(onViewTrendsTapped: {
                                showFullTimeline = true
                            })

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
        .sheet(isPresented: $showCreateReminder) {
            CreateReminderSheet()
        }
        .sheet(item: $reminderToEdit) { reminder in
            CreateReminderSheet(existingReminder: reminder)
        }
        .fullScreenCover(isPresented: $showFullTimeline) {
            FullTimelineView()
        }
    }
    
    @ViewBuilder
    private var upNextRemindersSection: some View {
        let petId = petStore.activePet?.id ?? UUID()
        let petReminders = reminderStore.reminders(for: petId)
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("UP NEXT")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.ink900.opacity(0.6))
                    .kerning(1.2)
                
                Spacer()
                
                Button(action: { showCreateReminder = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.sage)
                }
            }
            
            if petReminders.isEmpty {
                Button(action: { showCreateReminder = true }) {
                    HStack {
                        Image(systemName: "bell.badge.plus")
                            .foregroundColor(.sage)
                        Text("Add a reminder for \(petStore.activePet?.name ?? "Buddy")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.ink900)
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.sage.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.sage.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(petReminders) { reminder in
                            ReminderPillView(reminder: reminder, onLogTapped: {
                                // For now, let's open quick log pre-filled, or just log directly
                                Task { @MainActor in
                                    if let category = LogCategory(rawValue: reminder.categoryId) {
                                        let newLog = LogEntry(
                                            id: UUID(),
                                            petId: reminder.petId,
                                            category: category,
                                            note: "Logged from Reminder"
                                        )
                                        if let userId = try? await SupabaseManager.shared.client.auth.session.user.id {
                                            await logStore.saveLog(newLog, userId: userId)
                                        }
                                    }
                                }
                            }, onEditTapped: {
                                reminderToEdit = reminder
                            }, onDeleteTapped: {
                                reminderStore.deleteReminder(reminder)
                            })
                        }
                    }
                    // padding so shadow doesn't clip
                    .padding(.vertical, 8) 
                }
                .padding(.horizontal, -20)
                .padding(.leading, 20)
            }
        }
    }
}

#Preview {
    HomeScreen()
}
