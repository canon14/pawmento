import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: Tab
    
    enum Tab {
        case home, log, coach, pet
    }
    
    var body: some View {
        HStack {
            NavBarItem(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == .home,
                action: { selectedTab = .home }
            )
            
            Spacer()
            
            NavBarItem(
                icon: "plus.circle.fill",
                title: "Log",
                isSelected: selectedTab == .log,
                action: { selectedTab = .log }
            )
            
            Spacer()
            
            NavBarItem(
                icon: "brain.head.profile",
                title: "Coach",
                isSelected: selectedTab == .coach,
                hasPulse: true,
                action: { selectedTab = .coach }
            )
            
            Spacer()
            
            NavBarItem(
                icon: "pawprint.fill",
                title: "Pet",
                isSelected: selectedTab == .pet,
                action: { selectedTab = .pet }
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 24) // Extra padding for safe area
        .background(Color.surfaceContainer)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: Color(hex: "6b5e51").opacity(0.08), radius: 30, x: 0, y: -10)
    }
}

struct NavBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var hasPulse: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.headlineLG)
                        .foregroundColor(isSelected ? .onPrimaryContainer : .onSurfaceVariant)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(isSelected ? Color.primaryContainer : Color.clear)
                        .clipShape(Capsule())
                    
                    if hasPulse {
                        Circle()
                            .fill(Color.error)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle().stroke(Color.surfaceContainer, lineWidth: 1)
                            )
                            .offset(x: -8, y: 0)
                    }
                }
                
                Text(title)
                    .font(.labelSM)
                    .foregroundColor(isSelected ? .onSurface : .onSurfaceVariant)
            }
        }
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
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

#Preview {
    BottomNavBar(selectedTab: .constant(.home))
}
