import Foundation
import Combine
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String? = nil
    
    // Flag to tell the UI that the user needs to check their email
    @Published var needsEmailConfirmation: Bool = false
    
    // Centralized magic string
    private let onboardingKey = "hasCompletedOnboarding"
    
    func getCurrentUserId() async -> UUID? {
        try? await SupabaseManager.shared.client.auth.session.user.id
    }
    
    func getCurrentUserEmail() async -> String? {
        try? await SupabaseManager.shared.client.auth.session.user.email
    }
    
    // MARK: - Safe Error Mapping
    
    /// Maps raw backend errors to safe, user-friendly strings without leaking details.
    private func mapAuthError(_ error: Error) -> String {
        print("Auth Error: \(error)") // Always log raw error for telemetry/debugging
        
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return "No internet connection. Please check your network and try again."
        }
        
        let errorDesc = error.localizedDescription.lowercased()
        if errorDesc.contains("invalid login") || errorDesc.contains("invalid credentials") {
            return "Invalid email or password. Please try again."
        } else if errorDesc.contains("already registered") {
            return "This email is already in use. Please sign in instead."
        } else if errorDesc.contains("password should be") {
            return "Password is too weak. Please choose a stronger password."
        }
        
        return "Authentication failed. Please try again later."
    }
    
    // MARK: - Validation
    
    /// Client-side validation to fail fast before hitting the network
    private func validateInputs(email: String, password: String) -> Bool {
        guard !email.isEmpty, email.contains("@") else {
            authError = "Please enter a valid email address."
            return false
        }
        guard password.count >= 6 else {
            authError = "Password must be at least 6 characters."
            return false
        }
        return true
    }
    
    // MARK: - Auth Methods
    
    // Check if there is an existing session
    func checkSession() async {
        do {
            // The Supabase swift SDK natively handles background refreshing and validation
            // If the session is hopelessly expired, this will throw.
            _ = try await SupabaseManager.shared.client.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }
    
    // Email Sign In
    func signIn(email: String, password: String) async {
        guard validateInputs(email: email, password: password) else { return }
        
        isLoading = true
        authError = nil
        do {
            _ = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            authError = mapAuthError(error)
            isAuthenticated = false
        }
        isLoading = false
    }
    
    // Email Sign Up
    func signUp(email: String, password: String) async {
        guard validateInputs(email: email, password: password) else { return }
        
        isLoading = true
        authError = nil
        needsEmailConfirmation = false
        
        do {
            let response = try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
            
            if response.session != nil {
                // User has an active session, skip email confirmation
                UserDefaults.standard.set(false, forKey: onboardingKey)
                isAuthenticated = true
            } else {
                // Email confirmation is required by Supabase settings
                needsEmailConfirmation = true
                isAuthenticated = false
            }
        } catch {
            authError = mapAuthError(error)
            isAuthenticated = false
        }
        isLoading = false
    }
    
    // Sign Out
    func signOut() async {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
        isAuthenticated = false
        needsEmailConfirmation = false
    }
    
    // Delete Account
    func deleteAccount() async {
        isLoading = true
        authError = nil
        do {
            _ = try await SupabaseManager.shared.client.rpc("delete_user").execute()
            await signOut()
        } catch {
            print("Failed to delete user via RPC: \(error)")
            // Keep the user signed in, just surface a polite UX failure state.
            authError = "Account deletion failed. Please try again or contact support."
        }
        isLoading = false
    }
    
    // Apple Sign In
    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        authError = nil
        do {
            let response = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            
            // Check if lastSignInAt is within 5 seconds of createdAt to reliably detect new users
            let user = response.user
            let lastSignIn = user.lastSignInAt ?? user.createdAt
            let isNewUser = abs(user.createdAt.timeIntervalSince(lastSignIn)) < 5.0
            
            if isNewUser {
                UserDefaults.standard.set(false, forKey: onboardingKey)
            }
            
            isAuthenticated = true
        } catch {
            authError = mapAuthError(error)
            isAuthenticated = false
        }
        isLoading = false
    }
}
