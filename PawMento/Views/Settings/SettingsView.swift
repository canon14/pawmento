import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @EnvironmentObject var toastManager: ToastManager
    
    @State private var userEmail: String = "Loading..."
    @State private var displayName: String = "PawMento User"
    
    // Delete Account State
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var isDeleting = false
    
    // Paywall State
    @State private var showPaywall = false
    
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
                                        LinearGradient(colors: [Color.primary, Color.primary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.primary.opacity(0.25), radius: 12, x: 0, y: 6)
                                
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
                        
                        // Account & Household Section
                        SettingsSection(title: "ACCOUNT") {
                            SettingsRow(icon: "star.fill", iconColor: .primary, title: "Manage Subscription") {
                                HStack {
                                    Text("Free")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .clipShape(Capsule())
                                        .shadow(color: Color.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.tertiaryText)
                                        .padding(.leading, 4)
                                }
                            } action: {
                                showPaywall = true
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
                            SettingsRow(icon: "bell.badge.fill", iconColor: .orange, title: "Push Notifications") {
                                Text("Coming Soon")
                                    .font(.labelSM)
                                    .foregroundColor(.tertiaryText)
                            } action: {
                                toastManager.show("Push Notifications coming soon", actionLabel: nil, action: nil)
                            }
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
                                Task {
                                    await authManager.signOut()
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
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
                        }
                        .padding(.horizontal, 20)
                        
                        // App Version Footer
                        VStack(spacing: 4) {
                            Text("PawMento")
                                .font(.labelSemibold)
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
            .disabled(isDeleting)
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
                    if let email = await authManager.getCurrentUserEmail() {
                        userEmail = email
                        // Derive display name from email (text before @)
                        let nameFromEmail = email.components(separatedBy: "@").first ?? "User"
                        displayName = nameFromEmail
                            .replacingOccurrences(of: ".", with: " ")
                            .replacingOccurrences(of: "_", with: " ")
                            .capitalized
                    } else {
                        userEmail = "user@example.com"
                    }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                TextField("Type 'delete me'", text: $deleteConfirmationText)
                
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                
                Button("Delete", role: .destructive) {
                    if deleteConfirmationText.lowercased() == "delete me" {
                        isDeleting = true
                        Task {
                            await authManager.deleteAccount()
                            dismiss()
                        }
                    } else {
                        toastManager.show("Account deletion cancelled. Text did not match.", actionLabel: nil, action: nil)
                    }
                    deleteConfirmationText = ""
                }
                .disabled(deleteConfirmationText.lowercased() != "delete me")
            } message: {
                Text("This action cannot be undone. All your pets, logs, and data will be permanently deleted. Type 'delete me' to confirm.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallSheet()
            }
        }
    }
}

// MARK: - Components

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
                .tint(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.surfaceContainerLowest)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(Color.primary.opacity(0.05))
            .padding(.leading, 72)
            .padding(.trailing, 20)
    }
}

struct SettingsRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.primary.opacity(0.05) : Color.surfaceContainerLowest)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
