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
    @EnvironmentObject var coachViewModel: CoachViewModel
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var reminderStore = ReminderStore.shared
    @StateObject private var homeViewModel = HomeViewModel()
    
    @State private var showCreateReminder = false
    @State private var reminderToEdit: Reminder? = nil
    @State private var showFullTimeline = false
    @State private var isFetchingReminders = false
    
    private static let wellnessSectionHeight: CGFloat = 360
    private static let upNextBodyHeight: CGFloat = 132
    private static let timelineSectionHeight: CGFloat = 280

    
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
            
            if homeViewModel.celebration == .firstLog {
                CelebrationOverlay {
                    homeViewModel.acknowledgeCelebration()
                }
                .transition(.opacity)
                .zIndex(10)
            }
            
            if homeViewModel.celebration == .firstInsight {
                CelebrationOverlay(message: "Your first pattern unlocked!") {
                    homeViewModel.acknowledgeCelebration()
                }
                .transition(.opacity)
                .zIndex(10)
            }
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
        .sheet(item: $homeViewModel.pendingStrongInsightPaywall, onDismiss: {
            homeViewModel.acknowledgeStrongInsightPaywall()
        }) { insight in
            PaywallSheet(
                insight: insight,
                trigger: .firstStrongInsight,
                petName: petStore.activePet?.name ?? PetStore.fallbackPetName
            )
        }
        .task(id: petStore.activePet?.id) {
            guard let petId = petStore.activePet?.id,
                  let pet = petStore.activePet else { return }
            isFetchingReminders = true
            async let logs: Void = logStore.fetchLogs(for: petId)
            async let meds: Void = medicationStore.fetchMedications(for: petId)
            async let reminders: Void = reminderStore.fetchReminders()
            _ = await (logs, meds, reminders)
            isFetchingReminders = false
            
            if logStore.logs.isEmpty {
                await coachViewModel.generateWelcomePrimer(for: pet)
            }
            refreshHomeState()
        }
        .onChange(of: logStore.logs.count) { _, _ in
            refreshHomeState()
        }
        .onChange(of: logStore.isFetching) { _, _ in
            refreshHomeState()
        }
        .onChange(of: medicationStore.medications.count) { _, _ in
            refreshHomeState()
        }
        .onChange(of: petStore.activePet?.id) { _, _ in
            homeViewModel.hasFirstInsight = false
            refreshHomeState()
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
                TopHeaderView(loggingStreak: homeViewModel.loggingStreak)
                
                VStack(spacing: 24) {
                    // ── Hero Zone ──
                    if isFirstRunHome {
                        WelcomeCoachCard(
                            onFollowUpTapped: { question in
                                openCoachChat(seeding: question)
                            },
                            onAskQuestionTapped: {
                                showCoachChat = true
                            }
                        )
                    }
                    
                    wellnessSection
                    
                    // ── Up Next ──
                    upNextRemindersSection
                    
                    // ── Today's one thing ──
                    todaysOneThingBanner
                    
                    // ── Today ──
                    TodayLogGrid(onLogAction: {
                        showQuickLog = true
                    })
                    
                    // ── Recent Activity ──
                    recentActivitySection
                    
                    // ── Quick Actions — static 2-up ──
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
    
    // MARK: - Stabilized sections
    
    @ViewBuilder
    private var wellnessSection: some View {
        if logStore.isFetching {
            SkeletonBlock()
                .frame(maxWidth: .infinity)
                .frame(height: Self.wellnessSectionHeight)
        } else if let error = logStore.fetchError, logStore.logs.isEmpty {
            homeSectionErrorCard(
                title: "Couldn't load wellness",
                detail: error,
                retry: {
                    Task {
                        guard let petId = petStore.activePet?.id else { return }
                        await logStore.fetchLogs(for: petId)
                        refreshHomeState()
                    }
                }
            )
            .frame(height: Self.wellnessSectionHeight)
        } else {
            WellnessScoreHero(
                ringMode: homeViewModel.ringMode,
                shouldPlayUnlockAnimation: homeViewModel.shouldPlayUnlockAnimation,
                onUnlockAnimationComplete: {
                    homeViewModel.acknowledgeUnlockAnimation()
                },
                onViewTrendsTapped: {
                    showFullTimeline = true
                },
                onAddPet: { showAddPetSheet = true }
            )
            .frame(minHeight: Self.wellnessSectionHeight)
        }
    }
    
    @ViewBuilder
    private var recentActivitySection: some View {
        if logStore.isFetching {
            VStack(alignment: .leading, spacing: 16) {
                SkeletonBlock(cornerRadius: AppRadius.sm)
                    .frame(width: 140, height: 18)
                SkeletonBlock(cornerRadius: AppRadius.sm)
                    .frame(height: 52)
                SkeletonBlock(cornerRadius: AppRadius.sm)
                    .frame(height: 52)
                SkeletonBlock(cornerRadius: AppRadius.sm)
                    .frame(height: 52)
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: Self.timelineSectionHeight)
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.card)
        } else if let error = logStore.fetchError, logStore.logs.isEmpty {
            homeSectionErrorCard(
                title: "Couldn't load activity",
                detail: error,
                retry: {
                    Task {
                        guard let petId = petStore.activePet?.id else { return }
                        await logStore.fetchLogs(for: petId)
                    }
                }
            )
            .frame(height: Self.timelineSectionHeight)
        } else {
            RecentActivityTimeline(
                petName: petStore.activePet?.name ?? PetStore.fallbackPetName,
                onLogCTA: { showQuickLog = true }
            )
            .frame(minHeight: Self.timelineSectionHeight)
        }
    }
    
    private func homeSectionErrorCard(title: String, detail: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.labelLG)
                .foregroundColor(.onSurface)
            Text(detail)
                .font(.caption)
                .foregroundColor(.onSurfaceVariant)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Button(action: retry) {
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
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warningBackground.opacity(0.5))
        .cornerRadius(AppRadius.card)
    }
    
    // MARK: - First Run
    
    private var isFirstRunHome: Bool {
        petStore.activePet != nil && !logStore.isFetching && logStore.logs.isEmpty
    }
    
    @ViewBuilder
    private var todaysOneThingBanner: some View {
        switch homeViewModel.todaysOneThing {
        case .nudge(let message):
            Button {
                showQuickLog = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.primary)
                    Text(message)
                        .font(.bodySM)
                        .foregroundColor(.onSurface)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.labelSM)
                        .foregroundColor(.onSurfaceVariant)
                }
                .padding(14)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(AppRadius.md)
            }
            .buttonStyle(.plain)
        case .done:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primary)
                Text("Done for today")
                    .font(.labelMD)
                    .foregroundColor(.onSurfaceVariant)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.md)
        case .none:
            EmptyView()
        }
    }
    
    private func refreshHomeState() {
        homeViewModel.refresh(
            pet: petStore.activePet,
            logs: logStore.logs,
            medications: medicationStore.medications,
            isFetchingLogs: logStore.isFetching
        )
    }
    
    private func openCoachChat(seeding question: String? = nil) {
        showCoachChat = true
        guard let question else { return }
        Task {
            let ownerId = await authManager.getCurrentUserId()
            await coachViewModel.sendMessage(question, pet: petStore.activePet, ownerId: ownerId)
        }
    }
    
    // MARK: - Quick Actions (static 2-up)
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Quick Actions")
            
            HStack(alignment: .top, spacing: 14) {
                PatternAlertCard(
                    setupProgress: homeViewModel.setupProgress,
                    action: {
                        selectedTab = .insights
                    },
                    onInsightsLoaded: { hasInsight in
                        if let petId = petStore.activePet?.id {
                            homeViewModel.updateHasFirstInsight(hasInsight, for: petId)
                        }
                        refreshHomeState()
                    },
                    onStrongInsightDetected: { insight in
                        Task {
                            if let userId = await authManager.getCurrentUserId() {
                                homeViewModel.presentFirstStrongInsightPaywallIfEligible(
                                    insight: insight,
                                    userId: userId,
                                    isPremium: coachViewModel.isPremium
                                )
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                
                AskCoachCard(action: {
                    showCoachChat = true
                })
                .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 170)
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
            
            Group {
                if isFetchingReminders && petReminders.isEmpty {
                    SkeletonBlock()
                } else if petReminders.isEmpty {
                    Button(action: { showCreateReminder = true }) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.primary)
                                Text("Set your first reminder")
                                    .font(.labelLG)
                                    .foregroundColor(.ink900)
                                Spacer()
                            }
                            Text("Never miss meals, meds, or walks for \(petStore.activePet?.name ?? PetStore.fallbackPetName).")
                                .font(.bodySM)
                                .foregroundColor(.onSurfaceVariant)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
                                        guard let category = LogCategory.fromStoredValue(reminder.categoryId) else { return }
                                        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                                            ToastManager.shared.show("Sign in again to log this reminder.", duration: 3.0)
                                            return
                                        }
                                        
                                        let sourceKey = NotificationManager.reminderPillLogSourceKey(reminderId: reminder.id)
                                        let newLog = LogEntry(
                                            id: UUID(),
                                            petId: reminder.petId,
                                            category: category,
                                            note: "Logged from Reminder",
                                            sourceKey: sourceKey
                                        )
                                        
                                        do {
                                            let inserted = try await logStore.saveLogIfAbsent(newLog, userId: userId)
                                            if inserted {
                                                ToastManager.shared.show("Logged from reminder")
                                            } else {
                                                ToastManager.shared.show("Already logged for today")
                                            }
                                        } catch {
                                            TelemetryEngine.shared.track(event: .error_occurred, properties: ["message": "Failed to log from reminder: \(error.localizedDescription)"])
                                            ToastManager.shared.show("Failed to log from reminder.", duration: 3.0)
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
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.upNextBodyHeight)
            .clipped()
        }
    }
}

#Preview {
    HomeScreen()
        .environmentObject(PetStore())
        .environmentObject(LogStore())
        .environmentObject(MedicationStore())
        .environmentObject(CoachViewModel())
        .environmentObject(AuthManager())
}
