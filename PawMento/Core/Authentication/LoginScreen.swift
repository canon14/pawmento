import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginScreen: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var currentNonce: String?
    
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
            
            // Auth Form
            VStack(spacing: AppSpacing.md) {
                
                // Apple Sign In Button
                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            guard let nonce = currentNonce else {
                                authManager.authError = "Invalid state: A login nonce was not found."
                                return
                            }
                            guard let appleIDToken = appleIDCredential.identityToken else {
                                authManager.authError = "Unable to fetch identity token"
                                return
                            }
                            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                                authManager.authError = "Unable to serialize token string from data"
                                return
                            }
                            Task {
                                await authManager.signInWithApple(idToken: idTokenString, nonce: nonce)
                            }
                        default:
                            break
                        }
                    case .failure(let error):
                        authManager.authError = "Apple Sign In failed: \(error.localizedDescription)"
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
                        
                    // Using standard SecureField matching our FormTextField style
                    SecureField("Password", text: $password)
                        .font(.bodyMD)
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(Color.surfaceContainerLowest)
                        .cornerRadius(AppRadius.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.input)
                                .stroke(Color.outlineVariant.opacity(0.5), lineWidth: 1)
                        )
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
            
            Spacer()
            
            // Toggle
            Button(action: {
                withAnimation {
                    isSignUp.toggle()
                    authManager.authError = nil
                }
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.labelMD)
                    .foregroundColor(.sage)
            }
            .padding(.bottom, AppSpacing.lg)
            
        }
        .background(Color.warmCream.ignoresSafeArea())
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
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
