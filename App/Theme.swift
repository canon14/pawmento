import SwiftUI

// MARK: - Design Tokens
struct AppSpacing {
    static let base: CGFloat = 8
    static let xs: CGFloat = 4
    static let sm: CGFloat = 12
    static let md: CGFloat = 20
    static let lg: CGFloat = 32
    static let xl: CGFloat = 48
    static let gutter: CGFloat = 16
}

struct AppRadius {
    static let sm: CGFloat = 4
    static let input: CGFloat = 12
    static let md: CGFloat = 16
    static let card: CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - Components
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ctaOnboarding)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isEnabled ? Color.sage : Color.sage.opacity(0.4)
            )
            .cornerRadius(AppRadius.input)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
    
    static let warning = Color(hex: "#F57F17")
    static let warningBackground = Color(hex: "#FFF8E1")
    static let warningBorder = Color(hex: "#FFE082")
    
    // Onboarding Colors
    static let warmCream = Color(hex: "#FBF7F1")
    static let tertiaryText = Color(hex: "#A8968A")
    static let warmTan = Color(hex: "#C89968")
    static let warmTanDark = Color(hex: "#B88858")
    static let sage = Color(hex: "#7A9E7E")
    
    static let warmTanTintBg = Color(hex: "#F5E8D3")
    static let sageTintBg = Color(hex: "#EAF2EB")
    static let warmCreamTintBg = Color(hex: "#FDF4E7")
    static let warmCoralTintBg = Color(hex: "#FDF0EC")
    
    static let primaryText = Color(hex: "#2A2520")
    static let secondaryText = Color(hex: "#6B5B4F")
    
    // Add First Pet Colors
    static let warmSand = Color(hex: "#D4C4B0")
    static let warmCoral = Color(hex: "#E47A6B")
    static let cream = Color(hex: "#F5EFE4")
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
    static let headlineXL = Font.custom("PlusJakartaSans-Bold", size: 40)
    static let headlineLG = Font.custom("PlusJakartaSans-SemiBold", size: 32)
    static let headlineMD = Font.custom("PlusJakartaSans-SemiBold", size: 24)
    static let headlineSM = Font.custom("PlusJakartaSans-SemiBold", size: 20)
    
    static let bodyLG = Font.custom("PlusJakartaSans-Regular", size: 18)
    static let bodyMD = Font.custom("PlusJakartaSans-Regular", size: 16)
    
    static let labelMD = Font.custom("PlusJakartaSans-Medium", size: 14)
    static let labelSM = Font.custom("PlusJakartaSans-SemiBold", size: 12)
    
    // Onboarding Fonts
    static let headlineOnboarding = Font.custom("PlusJakartaSans-Bold", size: 28)
    static let bodyOnboarding = Font.custom("PlusJakartaSans-Regular", size: 16)
    static let ctaOnboarding = Font.custom("PlusJakartaSans-SemiBold", size: 17)
    static let skipOnboarding = Font.custom("PlusJakartaSans-Medium", size: 14)
    
    // Add First Pet Fonts
    static let labelSemibold = Font.custom("PlusJakartaSans-SemiBold", size: 13)
    static let labelRegular = Font.custom("PlusJakartaSans-Regular", size: 13)
    static let labelLarge = Font.custom("PlusJakartaSans-Medium", size: 15)
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
