import Foundation
import Combine
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String? = nil
    
    // Check if there is an existing session
    func checkSession() async {
        do {
            _ = try await SupabaseManager.shared.client.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }
    
    // Email Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        do {
            _ = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            authError = error.localizedDescription
            isAuthenticated = false
        }
        isLoading = false
    }
    
    // Email Sign Up
    func signUp(email: String, password: String) async {
        isLoading = true
        authError = nil
        do {
            _ = try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
            // Note: If email confirmation is enabled in Supabase, they might not be authenticated yet.
            // For MVP, we assume we log them in immediately or handle it smoothly.
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            isAuthenticated = true
        } catch {
            authError = error.localizedDescription
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
    }
    
    // Apple Sign In (Stubbed logic for when token is retrieved)
    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        authError = nil
        do {
            let response = try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            // If the user was just created within the last 15 seconds, treat them as a brand new user
            let createdAt = response.user.createdAt
            if abs(createdAt.timeIntervalSinceNow) < 15 {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            }
            isAuthenticated = true
        } catch {
            authError = error.localizedDescription
            isAuthenticated = false
        }
        isLoading = false
    }
}
