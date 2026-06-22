import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @EnvironmentObject var toastManager: ToastManager
    
    @State private var userEmail: String = "Loading..."
    @State private var pushNotificationsEnabled = true
    
    // Delete Account State
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var isDeleting = false
    
    // Paywall State
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.primaryContainer)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(userEmail.prefix(1).uppercased())
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.onPrimaryContainer)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PawMento User")
                                .font(.headlineSM)
                                .foregroundColor(.primaryText)
                            Text(userEmail)
                                .font(.labelRegular)
                                .foregroundColor(.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Account & Household Section
                Section(header: Text("ACCOUNT").font(.labelSM).foregroundColor(.tertiaryText)) {
                    Button(action: {
                        showPaywall = true
                    }) {
                        HStack {
                            Label("Manage Subscription", systemImage: "star.fill")
                                .foregroundColor(.primaryText)
                            Spacer()
                            Text("Free")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.ink100)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Button(action: {
                        toastManager.show("Household Sharing coming soon", actionLabel: nil, action: nil)
                    }) {
                        HStack {
                            Label("Household & Family", systemImage: "person.2.fill")
                                .foregroundColor(.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
                
                // Preferences Section
                Section(header: Text("PREFERENCES").font(.labelSM).foregroundColor(.tertiaryText)) {
                    Toggle(isOn: $pushNotificationsEnabled) {
                        Label("Push Notifications", systemImage: "bell.badge.fill")
                            .foregroundColor(.primaryText)
                    }
                    .tint(.primary)
                }
                
                // Support Section
                Section(header: Text("SUPPORT").font(.labelSM).foregroundColor(.tertiaryText)) {
                    Button(action: {
                        toastManager.show("Help Center coming soon", actionLabel: nil, action: nil)
                    }) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                            .foregroundColor(.primaryText)
                    }
                    
                    Button(action: {
                        toastManager.show("Privacy Policy coming soon", actionLabel: nil, action: nil)
                    }) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .foregroundColor(.primaryText)
                    }
                    
                    Button(action: {
                        toastManager.show("Terms of Service coming soon", actionLabel: nil, action: nil)
                    }) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                            .foregroundColor(.primaryText)
                    }
                }
                
                // Danger Zone
                Section {
                    Button(action: {
                        Task {
                            await authManager.signOut()
                            dismiss()
                        }
                    }) {
                        Text("Sign Out")
                            .font(.bodyMD)
                            .foregroundColor(.primaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete Account")
                            .font(.bodyMD)
                            .foregroundColor(.error)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.background.edgesIgnoringSafeArea(.all))
            .disabled(isDeleting)
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Deleting Account...")
                            .padding()
                            .background(Color.surfaceBright)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .font(.headlineMD)
                }
            }
            .onAppear {
                Task {
                    if let email = await authManager.getCurrentUserEmail() {
                        userEmail = email
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

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
