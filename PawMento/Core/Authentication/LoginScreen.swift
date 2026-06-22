import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginScreen: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var currentNonce: String?
    @State private var confirmationResent = false
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            
            Spacer()
            
            // Header
            VStack(spacing: AppSpacing.sm) {
                Text("Welcome to PawMento")
                    .font(.headlineXL)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(isSignUp ? "Create an account to start your pet's wellness journey." : "Sign in to continue your pet's wellness journey.")
                    .font(.bodyLG)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }
            
            // Fix A3: Email confirmation banner
            if authManager.needsEmailConfirmation {
                emailConfirmationBanner
            } else {
                // Auth Form
                authFormContent
            }
            
            Spacer()
            
            // Toggle (hidden when showing confirmation banner)
            if !authManager.needsEmailConfirmation {
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                        authManager.authError = nil
                        authManager.needsEmailConfirmation = false
                    }
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.labelMD)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, AppSpacing.lg)
            }
            
        }
        .background(Color.warmCream.ignoresSafeArea())
    }
    
    // MARK: - Auth Form
    
    private var authFormContent: some View {
        VStack(spacing: AppSpacing.md) {
            
            // Apple Sign In Button
            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                Task {
                    await authManager.handleAppleSignInCompletion(result: result, currentNonce: currentNonce)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .cornerRadius(AppRadius.input)
            
            // Divider
            HStack {
                VStack { Divider().background(Color.outlineVariant) }
                Text("or")
                    .font(.labelMD)
                    .foregroundColor(.tertiaryText)
                VStack { Divider().background(Color.outlineVariant) }
            }
            .padding(.vertical, AppSpacing.sm)
            
            // Email / Password
            VStack(spacing: AppSpacing.sm) {
                FormTextField(placeholder: "Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: email) { _ in
                        authManager.authError = nil
                        // Reset confirmation state when email changes
                        authManager.needsEmailConfirmation = false
                        confirmationResent = false
                    }
                    
                FormSecureField(placeholder: "Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .onChange(of: password) { _ in authManager.authError = nil }
            }
            
            if let error = authManager.authError {
                Text(error)
                    .font(.labelSM)
                    .foregroundColor(.error)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: handleEmailAuth) {
                HStack {
                    if authManager.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, AppSpacing.xs)
                    }
                    Text(isSignUp ? "Sign Up" : "Sign In")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
            
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    // MARK: - Email Confirmation Banner (Fix A3)
    
    private var emailConfirmationBanner: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "envelope.badge")
                .font(.displayLG)
                .foregroundColor(.primary)
                .padding(.bottom, AppSpacing.xs)
            
            Text("Check Your Email")
                .font(.headlineMD)
                .foregroundColor(.primaryText)
            
            Text("We sent a confirmation link to **\(email)**. Tap the link to activate your account, then come back to sign in.")
                .font(.bodyMD)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
            
            if confirmationResent {
                Text("Confirmation email resent!")
                    .font(.labelSM)
                    .foregroundColor(.primary)
            }
            
            if let error = authManager.authError {
                Text(error)
                    .font(.labelSM)
                    .foregroundColor(.error)
                    .multilineTextAlignment(.center)
            }
            
            // Resend confirmation button
            Button(action: {
                Task {
                    await authManager.resendConfirmation(email: email)
                    if authManager.authError == nil {
                        confirmationResent = true
                    }
                }
            }) {
                HStack {
                    if authManager.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, AppSpacing.xs)
                    }
                    Text("Resend Confirmation Email")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(authManager.isLoading)
            
            // Back to sign-in button
            Button(action: {
                withAnimation {
                    authManager.needsEmailConfirmation = false
                    authManager.authError = nil
                    confirmationResent = false
                    isSignUp = false
                }
            }) {
                Text("Back to Sign In")
                    .font(.labelMD)
                    .foregroundColor(.primary)
            }
            .padding(.top, AppSpacing.sm)
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    private func handleEmailAuth() {
        Task {
            if isSignUp {
                await authManager.signUp(email: email, password: password)
            } else {
                await authManager.signIn(email: email, password: password)
            }
        }
    }
    
    // MARK: - Apple Sign In Helpers
    // Fix A5: Added missing 'W' to charset (was STUV_XYZ, now STUVWXYZ)
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

#Preview {
    LoginScreen()
        .environmentObject(AuthManager())
}
