import SwiftUI
import AuthenticationServices

struct LoginScreen: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
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
                    // Note: You need to add 'Sign In with Apple' capability in Xcode for this to fully work
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        // Extract idToken and nonce, then pass to authManager
                        print("Apple Sign In successful: \(authResults)")
                        // For a real app, extract ASAuthorizationAppleIDCredential and its identityToken
                        // authManager.signInWithApple(idToken: token, nonce: nonce)
                    case .failure(let error):
                        print("Apple Sign In failed: \(error.localizedDescription)")
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
}

#Preview {
    LoginScreen()
        .environmentObject(AuthManager())
}
