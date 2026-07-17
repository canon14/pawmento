import SwiftUI

// MARK: - Design Tokens
struct AppSpacing {
    static let base: CGFloat = 8
    static let xs: CGFloat = 8
    static let sm: CGFloat = 16
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
    static let xl: CGFloat = 48
    static let gutter: CGFloat = 16
    
    /// BottomNavBar content row + vertical paddings + scroll breathing room.
    static let bottomNavContentHeight: CGFloat = 44
    static let bottomNavTopPadding: CGFloat = 12
    static let bottomNavBottomPadding: CGFloat = 24
    static let bottomNavScrollBreathingRoom: CGFloat = 40
    static let bottomNavClearance: CGFloat =
        bottomNavContentHeight + bottomNavTopPadding + bottomNavBottomPadding + bottomNavScrollBreathingRoom
}

struct AppRadius {
    static let sm: CGFloat = 8
    static let input: CGFloat = 12
    static let md: CGFloat = 16
    static let card: CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - Modifiers
struct WarmShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color(hex: "6b5e51").opacity(0.08), radius: 30, x: 0, y: 10)
    }
}

extension View {
    func warmShadow() -> some View {
        self.modifier(WarmShadowModifier())
    }
}

// MARK: - Colors
extension Color {
    static let surface = Color(hex: "#fbf9f5")
    static let surfaceDim = Color(hex: "#dbdad6")
    static let surfaceBright = Color(hex: "#fbf9f5")
    static let surfaceContainerLowest = Color(hex: "#ffffff")
    static let surfaceContainerLow = Color(hex: "#f5f3ef")
    static let surfaceContainer = Color(hex: "#efeeea")
    static let surfaceContainerHigh = Color(hex: "#eae8e4")
    static let surfaceContainerHighest = Color(hex: "#e4e2de")
    
    static let onSurface = Color(hex: "#1b1c1a")
    static let onSurfaceVariant = Color(hex: "#444842")
    static let outline = Color(hex: "#757871")
    static let outlineVariant = Color(hex: "#c5c7bf")
    
    static let primary = Color(hex: "#576152")
    /// Explicit brand sage accent — prefer in views over bare `Color.primary` (shadows SwiftUI's label color).
    static let brandAccent = Color(hex: "#576152")
    static let onPrimary = Color(hex: "#ffffff")
    static let primaryContainer = Color(hex: "#d9e4d1")
    static let onPrimaryContainer = Color(hex: "#5c6657")
    static let primaryFixedDim = Color(hex: "#bfcab8")
    
    static let secondary = Color(hex: "#6b5d40")
    static let onSecondary = Color(hex: "#ffffff")
    static let secondaryContainer = Color(hex: "#f4e0bb")
    static let onSecondaryContainer = Color(hex: "#716345")
    
    static let background = Color(hex: "#fbf9f5")
    static let onBackground = Color(hex: "#1b1c1a")
    
    static let error = Color(hex: "#ba1a1a")
    static let onError = Color(hex: "#ffffff")
    
    static let warning = Color(hex: "#F57F17")
    static let warningBackground = Color(hex: "#FFF8E1")
    static let warningBorder = Color(hex: "#FFE082")
    
    // Core Semantic Tints
    static let warmCream = Color(hex: "#FBF7F1")
    static let tertiaryText = Color(hex: "#A8968A")
    static let primaryText = Color(hex: "#2A2520")
    static let secondaryText = Color(hex: "#6B5B4F")
    
    // Extracted Tints (Consolidated)
    static let warmTanTintBg = Color(hex: "#F5E8D3")
    static let sageTintBg = Color(hex: "#EAF2EB")
    static let warmCreamTintBg = Color(hex: "#FDF4E7")
    static let errorTintBg = Color(hex: "#FDF0EC") // Replaced warmCoralTintBg
    
    // Replaced warmCoralHue with coral500 for non-error distinct branding
    static let coral500 = Color(hex: "#E07856")
    static let amber = Color(hex: "#E8A547")
    
    static let ink900 = Color(hex: "#1B1C1A")
    static let ink700 = Color(hex: "#444842")
    static let ink600 = Color(hex: "#757871")
    static let ink500 = Color(hex: "#8D908A")
    static let ink300 = Color(hex: "#C5C7BF")
    static let ink200 = Color(hex: "#E4E2DE")
    static let ink100 = Color(hex: "#EAE8E4")
    
    // Surface aliases
    static let surface0 = Color(hex: "#FFFFFF")
    static let surface1 = Color(hex: "#F5F3EF")
}

// Helper to initialize Color from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    // Displays
    static let displayLG = Font.custom("PlusJakartaSans-Bold", size: 40)
    static let displayMD = Font.custom("PlusJakartaSans-Bold", size: 32)
    static let displaySM = Font.custom("PlusJakartaSans-Bold", size: 28)
    
    // Headlines
    static let headlineLG = Font.custom("PlusJakartaSans-SemiBold", size: 24)
    static let headlineMD = Font.custom("PlusJakartaSans-SemiBold", size: 20)
    static let headlineSM = Font.custom("PlusJakartaSans-SemiBold", size: 18)
    
    // Body (Regular)
    static let bodyLG = Font.custom("PlusJakartaSans-Regular", size: 18)
    static let bodyMD = Font.custom("PlusJakartaSans-Regular", size: 16)
    static let bodySM = Font.custom("PlusJakartaSans-Regular", size: 14)
    static let bodyXS = Font.custom("PlusJakartaSans-Regular", size: 13)
    
    // Labels (Medium/SemiBold)
    static let labelLG = Font.custom("PlusJakartaSans-SemiBold", size: 16)
    static let labelMD = Font.custom("PlusJakartaSans-Medium", size: 14)
    static let labelSM = Font.custom("PlusJakartaSans-SemiBold", size: 13)
    static let labelXS = Font.custom("PlusJakartaSans-SemiBold", size: 12)
    
    // Captions & Specialties
    static let caption = Font.custom("PlusJakartaSans-Regular", size: 12)
    static let captionTabular = Font.custom("PlusJakartaSans-Regular", size: 12).monospacedDigit()
    static let cta = Font.custom("PlusJakartaSans-SemiBold", size: 17)
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cta)
            .foregroundColor(.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isEnabled ? 
                LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) 
                : LinearGradient(colors: [Color.primary.opacity(0.4), Color.primary.opacity(0.4)], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(16)
            .shadow(color: isEnabled ? Color.primary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && isEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cta)
            .foregroundColor(isEnabled ? .primary : .primary.opacity(0.4))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.clear)
            .cornerRadius(AppRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.input)
                    .stroke(isEnabled ? Color.primary : Color.primary.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelMD)
            .foregroundColor(isEnabled ? .primary : .primary.opacity(0.4))
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cta)
            .foregroundColor(.onError)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? Color.error : Color.error.opacity(0.4))
            .cornerRadius(AppRadius.input)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && isEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
    }
}

extension Color {
    static let warmSand = Color(hex: "#D4C4B0")
    static let cream = Color(hex: "#F5EFE4")
    static let warmTanDarkHue = Color(hex: "#B88858")
    static let sageHue = Color(hex: "#7A9E7E")
    static let warmTanHue = Color(hex: "#C89968")
}

extension Color {
    static let sage50 = Color(hex: "#E8F1EF")
    static let sage200 = Color(hex: "#B3D1C9")
    static let sage700 = Color(hex: "#4A7369")
    static let red500 = Color(hex: "#C8412B")
}
