import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var coachViewModel: CoachViewModel
    
    @EnvironmentObject var toastManager: ToastManager
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    @State private var userEmail: String = "Loading..."
    @State private var displayName: String = "PawMento User"
    
    // Delete / Sign-out State
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var isDeleting = false
    @State private var isSigningOut = false
    @State private var isUpdatingNotifications = false
    
    // Subscription sheets
    @State private var showPaywall = false
    @State private var showSubscriptionManagement = false
    
    private var isDeleteConfirmationValid: Bool {
        deleteConfirmationText.lowercased() == "delete me"
    }
    
    private var isAccountActionInFlight: Bool {
        isSigningOut || isDeleting || authManager.isLoading
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // Profile Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [Color.brandAccent, Color.brandAccent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.brandAccent.opacity(0.25), radius: 12, x: 0, y: 6)
                                
                                Text(displayName.prefix(1).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text(displayName)
                                    .font(.headlineMD)
                                    .foregroundColor(.primaryText)
                                Text(userEmail)
                                    .font(.bodySM)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                        .padding(.top, 24)
                        
                        if coachViewModel.showSubscriptionLoadError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.warning)
                                Text("Couldn't refresh your subscription. Your plan is unchanged.")
                                    .font(.bodySM)
                                    .foregroundColor(.secondaryText)
                                Spacer(minLength: 0)
                                Button("Retry") {
                                    Task { await refreshSubscriptionEntitlement() }
                                }
                                .font(.bodySM.weight(.semibold))
                            }
                            .padding(12)
                            .background(Color.warning.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        // Account & Household Section
                        SettingsSection(title: "ACCOUNT") {
                            SettingsRow(icon: "star.fill", iconColor: .brandAccent, title: "Manage Subscription") {
                                HStack {
                                    SubscriptionPlanBadge(
                                        isPremium: coachViewModel.isPremium,
                                        loadState: coachViewModel.subscriptionLoadState
                                    )
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.tertiaryText)
                                        .padding(.leading, 4)
                                }
                            } action: {
                                Task { await handleManageSubscriptionTap() }
                            }
                            
                            SettingsDivider()
                            
                            SettingsRow(icon: "person.2.fill", iconColor: .blue, title: "Household & Family") {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.tertiaryText)
                            } action: {
                                toastManager.show("Household Sharing coming soon", actionLabel: nil, action: nil)
                            }
                        }
                        
                        // Preferences Section
                        SettingsSection(title: "PREFERENCES") {
                            SettingsNotificationStatusRow(
                                isAuthorized: notificationManager.isAuthorized,
                                isUpdating: isUpdatingNotifications,
                                onEnable: {
                                    Task { await enableNotifications() }
                                },
                                onOpenSettings: {
                                    openSystemSettings()
                                }
                            )
                        }
                        
                        // Support Section
                        SettingsSection(title: "SUPPORT") {
                            SettingsRow(icon: "questionmark.circle.fill", iconColor: .green, title: "Help Center") {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.tertiaryText)
                            } action: {
                                toastManager.show("Help Center coming soon", actionLabel: nil, action: nil)
                            }
                            
                            SettingsDivider()
                            
                            SettingsRow(icon: "hand.raised.fill", iconColor: .purple, title: "Privacy Policy") {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.tertiaryText)
                            } action: {
                                toastManager.show("Privacy Policy coming soon", actionLabel: nil, action: nil)
                            }
                            
                            SettingsDivider()
                            
                            SettingsRow(icon: "doc.text.fill", iconColor: .gray, title: "Terms of Service") {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.tertiaryText)
                            } action: {
                                toastManager.show("Terms of Service coming soon", actionLabel: nil, action: nil)
                            }
                        }
                        
                        // Danger Zone
                        VStack(spacing: 16) {
                            Button(action: {
                                Task { await handleSignOut() }
                            }) {
                                HStack {
                                    if isSigningOut {
                                        ProgressView()
                                            .padding(.trailing, 4)
                                    }
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text(isSigningOut ? "Signing Out..." : "Sign Out")
                                }
                                .font(.headlineSM)
                                .foregroundColor(.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.surfaceContainerLowest)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(SquishyCardStyle())
                            .disabled(isAccountActionInFlight)
                            
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Account")
                                }
                                .font(.headlineSM)
                                .foregroundColor(.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.error.opacity(0.1))
                                .cornerRadius(20)
                            }
                            .buttonStyle(SquishyCardStyle())
                            .disabled(isAccountActionInFlight)
                        }
                        .padding(.horizontal, 20)
                        
                        // App Version Footer
                        VStack(spacing: 4) {
                            Text("PawMento")
                                .font(.labelSM)
                                .foregroundColor(.tertiaryText)
                            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                                .font(.labelSM)
                                .foregroundColor(.tertiaryText.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headlineLG)
                            .foregroundColor(.tertiaryText)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .disabled(isDeleting || isSigningOut)
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Deleting Account...")
                            .padding(24)
                            .background(Color.surfaceContainerLowest)
                            .cornerRadius(24)
                            .shadow(radius: 10)
                    }
                }
            }
            .onAppear {
                Task {
                    await notificationManager.refreshAuthorization()
                    await refreshSubscriptionEntitlement()
                    await loadUserProfile()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .subscriptionEntitlementsDidChange)) { _ in
                Task { await refreshSubscriptionEntitlement() }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    await notificationManager.refreshAuthorization()
                    if userEmail == "Loading..." || userEmail == AuthManager.profileUnavailableEmail {
                        await loadUserProfile()
                    }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                TextField("Type 'delete me'", text: $deleteConfirmationText)
                
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                
                Button("Delete", role: .destructive) {
                    isDeleting = true
                    deleteConfirmationText = ""
                    Task { await handleDeleteAccount() }
                }
                .disabled(!isDeleteConfirmationValid || isAccountActionInFlight)
            } message: {
                Text("This action cannot be undone. All your pets, logs, and data will be permanently deleted. Type 'delete me' to confirm.")
            }
            .sheet(isPresented: $showPaywall, onDismiss: {
                Task { await refreshSubscriptionEntitlement() }
            }) {
                PaywallSheet()
            }
            .sheet(isPresented: $showSubscriptionManagement, onDismiss: {
                Task { await refreshSubscriptionEntitlement() }
            }) {
                SubscriptionManagementSheet()
            }
        }
    }
    
    private func refreshSubscriptionEntitlement() async {
        guard let ownerId = await authManager.getCurrentUserId() else { return }
        await coachViewModel.initializeQuotaAndSubscription(ownerId: ownerId)
    }
    
    private func handleManageSubscriptionTap() async {
        if coachViewModel.subscriptionLoadState != .loaded {
            await refreshSubscriptionEntitlement()
        }
        
        guard coachViewModel.subscriptionLoadState == .loaded else {
            toastManager.show(
                "Couldn't verify your subscription. Check your connection and try again.",
                duration: 4.0
            )
            return
        }
        
        if coachViewModel.isPremium {
            showSubscriptionManagement = true
        } else {
            showPaywall = true
        }
    }
    
    private func loadUserProfile() async {
        if let profile = await authManager.fetchSettingsProfile() {
            userEmail = profile.email
            displayName = profile.displayName
        } else {
            userEmail = AuthManager.profileUnavailableEmail
            displayName = AuthManager.profileUnavailableName
        }
    }
    
    private func handleSignOut() async {
        guard !isAccountActionInFlight else { return }
        isSigningOut = true
        defer { isSigningOut = false }
        
        let success = await authManager.signOut()
        if success {
            dismiss()
        } else {
            toastManager.show(
                "Couldn't sign out. Please try again.",
                duration: 4.0
            )
        }
    }
    
    private func handleDeleteAccount() async {
        guard !isSigningOut else {
            isDeleting = false
            return
        }
        
        let success = await authManager.deleteAccount()
        if success {
            // Surface partial signOut messaging if present, then dismiss into logged-out state.
            if let message = authManager.authError, message.contains("Account deleted") {
                toastManager.show(message, duration: 4.0)
            }
            dismiss()
        } else {
            isDeleting = false
            toastManager.show(
                authManager.authError ?? "Account deletion failed. Please try again or contact support.",
                duration: 4.0
            )
        }
    }
    
    private func enableNotifications() async {
        guard !isUpdatingNotifications else { return }
        isUpdatingNotifications = true
        defer { isUpdatingNotifications = false }
        
        let granted = await notificationManager.requestAuthorization()
        if granted {
            let enabledReminders = ReminderStore.shared.reminders.filter { $0.isEnabled }
            await notificationManager.syncNotifications(enabledReminders: enabledReminders)
        } else {
            toastManager.show(
                "Notifications are off. Enable them in Settings to receive reminders.",
                duration: 4.0
            )
            openSystemSettings()
        }
    }
    
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

// MARK: - Components

private struct SubscriptionPlanBadge: View {
    let isPremium: Bool
    let loadState: SubscriptionLoadState
    
    private var label: String {
        switch loadState {
        case .loaded:
            return isPremium ? "Pro" : "Free"
        case .failed:
            return "Retry"
        case .unknown:
            return "—"
        }
    }
    
    private var showsProStyle: Bool {
        loadState == .loaded && isPremium
    }
    
    var body: some View {
        Text(label)
            .font(.caption.weight(.bold))
            .foregroundColor(showsProStyle ? .white : .secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                if showsProStyle {
                    LinearGradient(
                        colors: [Color.brandAccent, Color.brandAccent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.surfaceContainer
                }
            }
            .clipShape(Capsule())
            .overlay {
                if !showsProStyle {
                    Capsule()
                        .stroke(Color.outlineVariant.opacity(0.6), lineWidth: 1)
                }
            }
            .shadow(color: showsProStyle ? Color.brandAccent.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: label)
    }
}

private struct SettingsNotificationStatusRow: View {
    let isAuthorized: Bool
    let isUpdating: Bool
    let onEnable: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Push Notifications")
                    .font(.bodyMD)
                    .foregroundColor(.primaryText)
                Text(isAuthorized ? "On" : "Off")
                    .font(.labelSM)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            if isUpdating {
                ProgressView()
            } else if isAuthorized {
                Button("Open Settings", action: onOpenSettings)
                    .font(.labelSM.weight(.semibold))
                    .foregroundColor(.brandAccent)
            } else {
                Button("Enable", action: onEnable)
                    .font(.labelSM.weight(.semibold))
                    .foregroundColor(.brandAccent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.surfaceContainerLowest)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(.tertiaryText)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color.surfaceContainerLowest)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let trailing: () -> Trailing
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.bodyMD)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                trailing()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.surfaceContainerLowest)
        }
        .buttonStyle(SettingsRowStyle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Toggle(title, isOn: $isOn)
                .font(.bodyMD)
                .foregroundColor(.primaryText)
                .tint(.brandAccent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.surfaceContainerLowest)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(Color.outlineVariant.opacity(0.35))
            .padding(.leading, 72)
            .padding(.trailing, 20)
    }
}

struct SettingsRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.brandAccent.opacity(0.08) : Color.surfaceContainerLowest)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(CoachViewModel())
        .environmentObject(ToastManager.shared)
}
