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
    
    // Entrance animation states
    @State private var heroVisible = false
    @State private var formVisible = false
    @State private var footerVisible = false
    
    var body: some View {
        ZStack {
            // Warm gradient background
            LinearGradient(
                colors: [Color.warmCream, Color.background, Color.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    Spacer().frame(height: 60)
                    
                    // MARK: - Brand Hero
                    brandHero
                        .opacity(heroVisible ? 1 : 0)
                        .offset(y: heroVisible ? 0 : 20)
                    
                    Spacer().frame(height: 40)
                    
                    // MARK: - Auth Content
                    Group {
                        if authManager.needsEmailConfirmation {
                            emailConfirmationBanner
                        } else {
                            authFormContent
                        }
                    }
                    .opacity(formVisible ? 1 : 0)
                    .offset(y: formVisible ? 0 : 15)
                    
                    Spacer().frame(height: 24)
                    
                    // Toggle (hidden when showing confirmation banner)
                    if !authManager.needsEmailConfirmation {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isSignUp.toggle()
                                authManager.authError = nil
                                authManager.needsEmailConfirmation = false
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? **Sign In**" : "Don't have an account? **Sign Up**")
                                .font(.bodySM)
                                .foregroundColor(.secondaryText)
                        }
                        .opacity(footerVisible ? 1 : 0)
                        .padding(.bottom, AppSpacing.lg)
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                heroVisible = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
                formVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
                footerVisible = true
            }
        }
    }
    
    // MARK: - Brand Hero
    
    private var brandHero: some View {
        VStack(spacing: 20) {
            // Animated Paw Logo Mark
            LoginHeroIllustration()
                .frame(width: 180, height: 180)
            
            VStack(spacing: 8) {
                Text("PawMento")
                    .font(.displayMD)
                    .foregroundColor(.primaryText)
                    .tracking(-0.5)
                
                Text("Your pet's health, beautifully journaled.")
                    .font(.bodyMD)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
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
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            
            // Divider
            HStack(spacing: 16) {
                Rectangle()
                    .fill(Color.outlineVariant.opacity(0.5))
                    .frame(height: 1)
                Text("or continue with email")
                    .font(.labelSM)
                    .foregroundColor(.tertiaryText)
                    .lineLimit(1)
                    .fixedSize()
                Rectangle()
                    .fill(Color.outlineVariant.opacity(0.5))
                    .frame(height: 1)
            }
            .padding(.vertical, AppSpacing.xs)
            
            // Email / Password
            VStack(spacing: 12) {
                FormTextField(placeholder: "Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: email) { _, _ in
                        authManager.authError = nil
                        authManager.needsEmailConfirmation = false
                        confirmationResent = false
                    }
                    
                FormSecureField(placeholder: "Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .onChange(of: password) { _, _ in authManager.authError = nil }
            }
            
            if let error = authManager.authError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.labelSM)
                    Text(error)
                        .font(.labelSM)
                }
                .foregroundColor(.error)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.errorTintBg)
                .cornerRadius(AppRadius.sm)
            }
            
            Button(action: handleEmailAuth) {
                HStack {
                    if authManager.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, AppSpacing.xs)
                    }
                    Text(isSignUp ? "Create Account" : "Sign In")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
            
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    // MARK: - Email Confirmation Banner
    
    private var emailConfirmationBanner: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.primary.opacity(0.15), Color.primary.opacity(0.05)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "envelope.badge")
                    .font(.system(size: 36))
                    .foregroundColor(.primary)
            }
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
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Confirmation email resent!")
                }
                .font(.labelSM)
                .foregroundColor(.primary)
                .padding(12)
                .background(Color.sageTintBg)
                .cornerRadius(AppRadius.sm)
            }
            
            if let error = authManager.authError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.labelSM)
                    Text(error)
                        .font(.labelSM)
                }
                .foregroundColor(.error)
                .multilineTextAlignment(.center)
                .padding(12)
                .background(Color.errorTintBg)
                .cornerRadius(AppRadius.sm)
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

// MARK: - Login Hero Illustration

struct LoginHeroIllustration: View {
    @State private var animate = false
    @State private var particleAnimate = false
    
    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.primary.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 40,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(animate ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animate)
            
            // Floating accent particles
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(particleColor(for: i))
                    .frame(width: particleSize(for: i), height: particleSize(for: i))
                    .offset(particleOffset(for: i))
                    .opacity(particleAnimate ? particleOpacity(for: i) : 0.1)
                    .scaleEffect(particleAnimate ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2.5...4.0))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.3),
                        value: particleAnimate
                    )
            }
            
            // Main card
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [Color.warmCreamTintBg, Color.warmTanTintBg.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.warmTanHue.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.warmTanHue.opacity(0.15), radius: 20, x: 0, y: 10)
            
            // Paw print cluster
            VStack(spacing: 4) {
                // Top two pads
                HStack(spacing: 14) {
                    PawPad(size: 18, color: Color.warmTanDarkHue.opacity(0.7))
                        .offset(y: 2)
                    PawPad(size: 18, color: Color.warmTanDarkHue.opacity(0.7))
                        .offset(y: 2)
                }
                // Bottom two pads
                HStack(spacing: 22) {
                    PawPad(size: 16, color: Color.warmTanDarkHue.opacity(0.55))
                    PawPad(size: 16, color: Color.warmTanDarkHue.opacity(0.55))
                }
                // Main pad
                PawPad(size: 30, color: Color.warmTanDarkHue.opacity(0.85))
                    .offset(y: -2)
            }
            .offset(y: -4)
            
            // Sparkle accents
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.sageHue.opacity(0.7))
                .offset(x: 55, y: -50)
                .scaleEffect(animate ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5), value: animate)
            
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.warmTanHue.opacity(0.6))
                .offset(x: -58, y: -42)
                .scaleEffect(animate ? 0.8 : 1.2)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(1.0), value: animate)
            
            Image(systemName: "heart.fill")
                .font(.system(size: 12))
                .foregroundColor(Color.coral500.opacity(0.5))
                .offset(x: 50, y: 45)
                .scaleEffect(animate ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.8), value: animate)
        }
        .onAppear {
            animate = true
            particleAnimate = true
        }
    }
    
    // Particle helpers
    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [
            .sageHue.opacity(0.4), .warmTanHue.opacity(0.35),
            .primary.opacity(0.25), .coral500.opacity(0.2),
            .sageHue.opacity(0.3), .warmTanHue.opacity(0.25)
        ]
        return colors[index % colors.count]
    }
    
    private func particleSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [10, 8, 12, 6, 9, 7]
        return sizes[index % sizes.count]
    }
    
    private func particleOffset(for index: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -70, height: -30),
            CGSize(width: 65, height: -55),
            CGSize(width: -55, height: 50),
            CGSize(width: 70, height: 30),
            CGSize(width: -30, height: -65),
            CGSize(width: 40, height: 60)
        ]
        return offsets[index % offsets.count]
    }
    
    private func particleOpacity(for index: Int) -> Double {
        let opacities: [Double] = [0.6, 0.5, 0.7, 0.4, 0.55, 0.45]
        return opacities[index % opacities.count]
    }
}

struct PawPad: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: size, height: size * 0.85)
    }
}

#Preview {
    LoginScreen()
        .environmentObject(AuthManager())
}
