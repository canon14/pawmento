import SwiftUI
import Supabase

struct HomeScreen: View {
    @State private var selectedTab: BottomNavBar.Tab = .home
    @State private var showCoachChat = false
    @State private var showQuickLog = false
    @State private var showAddPetSheet = false
    
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var medicationStore: MedicationStore
    @StateObject private var reminderStore = ReminderStore.shared
    
    @State private var showCreateReminder = false
    @State private var reminderToEdit: Reminder? = nil
    @State private var showFullTimeline = false

    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content ScrollView
            switch selectedTab {
            case .pet:
                PetProfileScreen()
                    .environmentObject(petStore)
                    .environmentObject(logStore)
            case .insights:
                InsightsScreen()
            default:
                homeContent
            }
            
            // Bottom Navigation
            VStack {
                Spacer()
                BottomNavBar(
                    selectedTab: $selectedTab,
                    onLogTap: { showQuickLog = true },
                    onCoachTap: { showCoachChat = true }
                )
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
        .sheet(isPresented: $showAddPetSheet) {
            AddPetSheet()
        }
        .task(id: petStore.activePet?.id) {
            guard let petId = petStore.activePet?.id else { return }
            async let logs: Void = logStore.fetchLogs(for: petId)
            async let meds: Void = medicationStore.fetchMedications(for: petId)
            async let reminders: Void = reminderStore.fetchReminders()
            _ = await (logs, meds, reminders)
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
    
    // MARK: - Home Content
    
    private var homeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                TopHeaderView()
                
                VStack(spacing: 24) {
                    // ── Hero Zone ──
                    PetSelectorCard(onAddPet: { showAddPetSheet = true })
                    
                    WellnessScoreHero(onViewTrendsTapped: {
                        showFullTimeline = true
                    })
                    
                    // ── Up Next ──
                    upNextRemindersSection
                    
                    // ── Loading / Error feedback ──
                    if logStore.isFetching {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.primary)
                            Text("Loading logs…")
                                .font(.bodySM)
                                .foregroundColor(.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    
                    if let error = logStore.fetchError {
                        VStack(spacing: 8) {
                            Text("Couldn't load logs")
                                .font(.labelLG)
                                .foregroundColor(.onSurface)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.onSurfaceVariant)
                                .lineLimit(2)
                            Button {
                                Task {
                                    guard let petId = petStore.activePet?.id else { return }
                                    await logStore.fetchLogs(for: petId)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .font(.labelSM)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.primaryContainer.opacity(0.3))
                                .cornerRadius(AppRadius.sm)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.warningBackground.opacity(0.5))
                        .cornerRadius(AppRadius.md)
                    }
                    
                    // ── Today ──
                    TodayLogGrid(onLogAction: {
                        showQuickLog = true
                    })
                    
                    // ── Recent Activity ──
                    RecentActivityTimeline()
                    
                    // ── Quick Actions — horizontally scrolling compact cards ──
                    quickActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .background(Color.background)
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Quick Actions (replaces side-by-side scaleEffect hack)
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Quick Actions")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    PatternAlertCard(action: {
                        selectedTab = .insights
                    })
                    .frame(width: 260)
                    
                    AskCoachCard(action: {
                        showCoachChat = true
                    })
                    .frame(width: 260)
                }
                .padding(.vertical, 4) // Prevent shadow clipping
            }
        }
    }
    
    // MARK: - Up Next Reminders
    
    @ViewBuilder
    private var upNextRemindersSection: some View {
        let petReminders: [Reminder] = {
            guard let petId = petStore.activePet?.id else { return [] }
            return reminderStore.reminders(for: petId)
        }()
        
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Up Next") {
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
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(AppRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(petReminders) { reminder in
                            ReminderPillView(reminder: reminder, onLogTapped: {
                                Task { @MainActor in
                                    if let category = LogCategory.fromStoredValue(reminder.categoryId) {
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
                    .padding(.vertical, 8)
                }
                .contentMargins(.horizontal, 20, for: .scrollContent)
            }
        }
    }
}

#Preview {
    HomeScreen()
        .environmentObject(PetStore())
        .environmentObject(LogStore())
        .environmentObject(MedicationStore())
        .environmentObject(CoachViewModel())
}
