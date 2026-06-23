import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: Tab
    var onLogTap: () -> Void
    var onCoachTap: () -> Void
    
    @Namespace private var animation
    
    enum Tab {
        case home, insights, pet
    }
    
    var body: some View {
        HStack {
            NavBarItem(
                id: .home,
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == .home,
                namespace: animation,
                action: { selectedTab = .home }
            )
            
            Spacer()
            
            NavBarItem(
                id: .insights,
                icon: "chart.line.uptrend.xyaxis",
                title: "Insights",
                isSelected: selectedTab == .insights,
                namespace: animation,
                action: { selectedTab = .insights }
            )
            
            Spacer()
            
            // Primary Action Button
            Button(action: onLogTap) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("Log")
                        .font(.labelMD)
                        .fontWeight(.bold)
                }
                .foregroundColor(.onPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.primary)
                .clipShape(Capsule())
                .shadow(color: Color.primary.opacity(0.3), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(SquishyNavStyle())
            
            Spacer()
            
            NavBarItem(
                id: nil,
                icon: "brain.head.profile",
                title: "Coach",
                isSelected: false,
                hasPulse: true,
                namespace: animation,
                action: onCoachTap
            )
            
            Spacer()
            
            NavBarItem(
                id: .pet,
                icon: "pawprint.fill",
                title: "Pet",
                isSelected: selectedTab == .pet,
                namespace: animation,
                action: { selectedTab = .pet }
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            Color.surfaceContainerLowest.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .overlay(
            RoundedCorner(radius: 24, corners: [.topLeft, .topRight])
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: -5)
    }
}

struct NavBarItem: View {
    let id: BottomNavBar.Tab?
    let icon: String
    let title: String
    let isSelected: Bool
    var hasPulse: Bool = false
    var namespace: Namespace.ID
    let action: () -> Void
    
    @State private var pulseAnimate = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.headlineLG)
                        .foregroundColor(isSelected ? .onPrimaryContainer : .onSurfaceVariant)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(
                            ZStack {
                                if isSelected {
                                    Capsule()
                                        .fill(Color.primaryContainer)
                                        .matchedGeometryEffect(id: "nav_indicator", in: namespace)
                                }
                            }
                        )
                        .clipShape(Capsule())
                    
                    if hasPulse {
                        ZStack {
                            // Animated pulse ring
                            Circle()
                                .stroke(Color.primary.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulseAnimate ? 2.2 : 1.0)
                                .opacity(pulseAnimate ? 0.0 : 0.6)
                                .animation(
                                    .easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                    value: pulseAnimate
                                )
                            
                            // Core dot
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle().stroke(Color.surfaceContainerLowest, lineWidth: 1.5)
                                )
                        }
                        .offset(x: -6, y: -1)
                    }
                }
                
                Text(title)
                    .font(.labelSM)
                    .foregroundColor(isSelected ? .onSurface : .onSurfaceVariant)
            }
        }
        .buttonStyle(SquishyNavStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onAppear {
            if hasPulse {
                pulseAnimate = true
            }
        }
    }
}

struct SquishyNavStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

#Preview {
    ZStack {
        Color.background.ignoresSafeArea()
        VStack {
            Spacer()
            BottomNavBar(selectedTab: .constant(.home), onLogTap: {}, onCoachTap: {})
        }
    }
}
