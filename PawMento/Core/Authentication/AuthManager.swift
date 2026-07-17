import Foundation
import Combine
import Supabase
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String? = nil
    
    // Flag to tell the UI that the user needs to check their email
    @Published var needsEmailConfirmation: Bool = false
    
    // Flag for per-user onboarding state
    @Published var hasCompletedOnboarding: Bool = false
    
    func getCurrentUserId() async -> UUID? {
        try? await SupabaseManager.shared.client.auth.session.user.id
    }
    
    func getCurrentUserEmail() async -> String? {
        try? await SupabaseManager.shared.client.auth.session.user.email
    }
    
    static let profileUnavailableEmail = "Email unavailable"
    static let profileUnavailableName = "PawMento User"
    
    struct SettingsProfile {
        let email: String
        let displayName: String
    }
    
    /// Loads email and display name for settings. Prefers `users.full_name` over email local-part.
    /// Retries once on transient session/profile fetch failure.
    func fetchSettingsProfile() async -> SettingsProfile? {
        for attempt in 0..<2 {
            guard let userId = await getCurrentUserId(),
                  let email = await getCurrentUserEmail() else {
                if attempt == 0 {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    continue
                }
                return nil
            }
            
            let storedName = await fetchStoredFullName(userId: userId)
            return SettingsProfile(
                email: email,
                displayName: Self.resolveDisplayName(storedName: storedName, email: email)
            )
        }
        return nil
    }
    
    static func resolveDisplayName(storedName: String?, email: String) -> String {
        let trimmedStored = storedName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedStored, !trimmedStored.isEmpty {
            return trimmedStored
        }
        let localPart = email.components(separatedBy: "@").first ?? "User"
        return localPart
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    private func fetchStoredFullName(userId: UUID) async -> String? {
        struct UserProfileRow: Codable { let full_name: String? }
        do {
            let rows: [UserProfileRow] = try await SupabaseManager.shared.client
                .from("users")
                .select("full_name")
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            guard let row = rows.first else { return nil }
            let trimmed = row.full_name?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == true ? nil : trimmed
        } catch {
            print("Failed to fetch user profile name: \(error)")
            return nil
        }
    }
    
    /// Ensures `public.users` and `subscriptions` rows exist for the current session.
    /// Logs and continues on failure so auth is not blocked by transient races.
    func ensureUserBootstrap() async {
        do {
            try await UserBootstrap.ensure()
        } catch {
            print("Failed to bootstrap user profile: \(error)")
        }
    }
    
    // MARK: - Onboarding
    
    // Fix A6: Check UserDefaults first, then fall back to pet-presence query
    // so a user who onboarded on another device (or had UserDefaults wiped)
    // is not forced through onboarding again if they already have pets.
    func checkOnboardingState() async {
        guard let userId = await getCurrentUserId() else {
            hasCompletedOnboarding = false
            return
        }
        
        let key = "hasCompletedOnboarding_\(userId.uuidString)"
        if UserDefaults.standard.bool(forKey: key) {
            hasCompletedOnboarding = true
            return
        }
        
        // Fallback: if the user already has ≥1 pet, treat onboarding as complete.
        // This handles cross-device scenarios without requiring a server-side column.
        do {
            let pets: [PetDTO] = try await SupabaseManager.shared.client
                .from("pets")
                .select()
                .eq("owner_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            if !pets.isEmpty {
                UserDefaults.standard.set(true, forKey: key)
                hasCompletedOnboarding = true
                return
            }
        } catch {
            print("Failed to check pet presence for onboarding fallback: \(error)")
        }
        
        hasCompletedOnboarding = false
    }
    
    func completeOnboarding() async {
        if let userId = await getCurrentUserId() {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(userId.uuidString)")
            hasCompletedOnboarding = true
        }
    }
    
    // MARK: - Safe Error Mapping
    
    // Fix A4: Use typed AuthError / ErrorCode from supabase-swift 2.46.0
    // instead of fragile English substring matching.
    /// Maps raw backend errors to safe, user-friendly strings without leaking details.
    private func mapAuthError(_ error: Error) -> String {
        print("Auth Error: \(error)") // Always log raw error for telemetry/debugging
        
        // Network errors
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return "No internet connection. Please check your network and try again."
        }
        
        // Typed Supabase AuthError matching
        if let authError = error as? AuthError {
            switch authError {
            case .weakPassword:
                return "Password is too weak. Please choose a stronger password."
            case .api(_, let errorCode, _, _):
                switch errorCode {
                case .invalidCredentials, .emailNotConfirmed:
                    return "Invalid email or password. Please try again."
                case .userAlreadyExists, .emailExists:
                    return "This email is already in use. Please sign in instead."
                case .weakPassword:
                    return "Password is too weak. Please choose a stronger password."
                case .overRequestRateLimit, .overEmailSendRateLimit:
                    return "Too many attempts. Please wait a moment and try again."
                case .signupDisabled:
                    return "Sign up is currently disabled. Please try again later."
                case .userBanned:
                    return "This account has been suspended."
                case .validationFailed:
                    return "Please check your email and password format."
                default:
                    return "Authentication failed. Please try again later."
                }
            default:
                return "Authentication failed. Please try again later."
            }
        }
        
        return "Authentication failed. Please try again later."
    }
    
    // MARK: - Validation
    
    // Fix A7: Stricter email validation using NSPredicate regex
    // instead of a bare contains("@") check.
    /// Client-side validation to fail fast before hitting the network
    private func validateInputs(email: String, password: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@",
            "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
        guard !trimmed.isEmpty, emailPredicate.evaluate(with: trimmed) else {
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
    // Fix A1: Also load onboarding state on cold launch so the flag is correct
    // before isAuthenticated triggers the view switch.
    func checkSession() async {
        do {
            // The Supabase swift SDK natively handles background refreshing and validation
            // If the session is hopelessly expired, this will throw.
            _ = try await SupabaseManager.shared.client.auth.session
            await ensureUserBootstrap()
            await checkOnboardingState()
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }
    
    // Email Sign In
    // Fix A1: Call checkOnboardingState() after successful authentication.
    func signIn(email: String, password: String) async {
        guard validateInputs(email: email, password: password) else { return }
        
        isLoading = true
        authError = nil
        do {
            _ = try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
            await ensureUserBootstrap()
            await checkOnboardingState()
            isAuthenticated = true
        } catch {
            authError = mapAuthError(error)
            isAuthenticated = false
        }
        isLoading = false
    }
    
    // Email Sign Up
    // Fix A1: Call checkOnboardingState() after successful authentication with session.
    func signUp(email: String, password: String) async {
        guard validateInputs(email: email, password: password) else { return }
        
        isLoading = true
        authError = nil
        needsEmailConfirmation = false
        
        do {
            let response = try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
            
            if response.session != nil {
                // User has an active session, skip email confirmation
                await ensureUserBootstrap()
                await checkOnboardingState()
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
    
    // Resend email confirmation (Fix A3 support)
    func resendConfirmation(email: String) async {
        isLoading = true
        authError = nil
        do {
            try await SupabaseManager.shared.client.auth.resend(email: email, type: .signup)
        } catch {
            authError = "Failed to resend confirmation email. Please try again."
            print("Resend confirmation error: \(error)")
        }
        isLoading = false
    }
    
    // Sign Out
    @discardableResult
    func signOut() async -> Bool {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            isAuthenticated = false
            needsEmailConfirmation = false
            hasCompletedOnboarding = false
            return true
        } catch {
            print("Error signing out: \(error)")
            return false
        }
    }
    
    // Delete Account
    @discardableResult
    func deleteAccount() async -> Bool {
        isLoading = true
        authError = nil
        defer { isLoading = false }
        
        do {
            _ = try await SupabaseManager.shared.client.rpc("delete_user").execute()
        } catch {
            print("Failed to delete user via RPC: \(error)")
            authError = "Account deletion failed. Please try again or contact support."
            return false
        }
        
        // Account is gone on the server — always tear down local session even if signOut fails.
        do {
            try await SupabaseManager.shared.client.auth.signOut()
        } catch {
            print("Account deleted but signOut failed: \(error)")
            authError = "Account deleted. Please restart the app if you stay signed in."
        }
        
        isAuthenticated = false
        needsEmailConfirmation = false
        hasCompletedOnboarding = false
        return true
    }
    
    // Apple Sign In
    // Fix A1: Call checkOnboardingState() after successful authentication.
    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        authError = nil
        do {
            try await SupabaseManager.shared.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            
            // We no longer rely on brittle timestamp heuristics for new user detection.
            // Onboarding is driven entirely by the per-user flag and pet presence.
            
            await ensureUserBootstrap()
            await checkOnboardingState()
            isAuthenticated = true
        } catch {
            authError = mapAuthError(error)
            isAuthenticated = false
        }
        isLoading = false
    }
    
    // MARK: - Apple Sign In Result Handler
    
    /// Called from the View's ASAuthorizationControllerDelegate to encapsulate Apple errors
    // Fix A2: Only silence .canceled. Surface .unknown and all other codes via mapAuthError.
    func handleAppleSignInCompletion(result: Result<ASAuthorization, Error>, currentNonce: String?) async {
        switch result {
        case .success(let authResults):
            switch authResults.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                guard let nonce = currentNonce else {
                    authError = "Authentication failed: missing security nonce."
                    return
                }
                guard let appleIDToken = appleIDCredential.identityToken,
                      let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    authError = "Unable to process Apple identity token."
                    return
                }
                
                await signInWithApple(idToken: idTokenString, nonce: nonce)
                
            default:
                authError = "Unable to sign in with Apple at this time."
            }
            
        case .failure(let error):
            // Fix A2: Only silence explicit user cancellation.
            // .unknown often represents real failures (no iCloud account, entitlement issues).
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                return
            }
            
            authError = mapAuthError(error)
            print("Apple Sign In failed: \(error)")
        }
    }
}
