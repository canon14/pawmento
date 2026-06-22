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
    @State private var isFetchingLogs = false
    
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
                            
                            // Promoted clinical card
                            WellnessScoreHero(onViewTrendsTapped: {
                                showFullTimeline = true
                            })
                            
                            upNextRemindersSection
                            
                            TodayLogGrid(onLogAction: {
                                showQuickLog = true
                            })
                            
                            RecentActivityTimeline()
                            
                            // Deemphasized secondary/marketing cards
                            HStack(spacing: 12) {
                                PatternAlertCard(action: {
                                    showInsights = true
                                })
                                .scaleEffect(0.9)
                                
                                AskCoachCard(action: {
                                    showCoachChat = true
                                })
                                .scaleEffect(0.9)
                            }
                            
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
                BottomNavBar(selectedTab: $selectedTab, onLogTap: { showQuickLog = true }, onCoachTap: { showCoachChat = true })
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        
        .fullScreenCover(isPresented: $showCoachChat) {
            CoachChatView()
        }
        .sheet(isPresented: $showQuickLog) {
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
            guard let petId = newPetId, !isFetchingLogs else { return }
            Task {
                isFetchingLogs = true
                await logStore.fetchLogs(for: petId)
                isFetchingLogs = false
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
                    .font(.bodyXS)
                    .foregroundColor(.ink900.opacity(0.6))
                    .kerning(1.2)
                
                Spacer()
                
                Button(action: { showCreateReminder = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headlineMD)
                        .foregroundColor(.primary)
                }
            }
            
            if petReminders.isEmpty {
                Button(action: { showCreateReminder = true }) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.primary)
                        Text("Add a reminder for \(petStore.activePet?.name ?? PetStore.fallbackPetName)")
                            .font(.bodySM)
                            .foregroundColor(.ink900)
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(AppRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
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
                                            do {
                                                try await logStore.saveLog(newLog, userId: userId)
                                            } catch {
                                                TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Failed to log from reminder: \(error.localizedDescription)"])
                                            }
                                        }
                                    }
                                }
                            }, onEditTapped: {
                                reminderToEdit = reminder
                            }, onDeleteTapped: {
                                Task {
                                    do {
                                        try await reminderStore.deleteReminder(reminder)
                                    } catch {
                                        ToastManager.shared.show("Failed to delete reminder.", duration: 3.0)
                                    }
                                }
                            })
                        }
                    }
                    // padding so shadow doesn't clip
                    .padding(.vertical, 8) 
                }
                .contentMargins(.horizontal, 20, for: .scrollContent)
                
            }
        }
    }
}

#Preview {
    HomeScreen()
}
