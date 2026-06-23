import os

path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Home/BottomNavBar.swift"

content = """import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: Tab
    var onLogTap: () -> Void
    var onCoachTap: () -> Void
    
    @Namespace private var animation
    
    enum Tab {
        case home, pet
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
            
            // Floating Action Button (FAB)
            Button(action: onLogTap) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.onPrimary)
                    .frame(width: 56, height: 56)
                    .background(Color.primary)
                    .clipShape(Circle())
                    .shadow(color: Color.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .offset(y: -16) // Breaks out of the top of the pill
            
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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.surfaceContainerLowest.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
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
                        .padding(.horizontal, 16)
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
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle().stroke(Color.surfaceContainerLowest, lineWidth: 1)
                            )
                            .offset(x: -8, y: 0)
                    }
                }
                
                Text(title)
                    .font(.labelSM)
                    .foregroundColor(isSelected ? .onSurface : .onSurfaceVariant)
            }
        }
        .buttonStyle(SquishyNavStyle())
    }
}

struct SquishyNavStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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
"""

with open(path, "w") as f:
    f.write(content)

print("Done")
