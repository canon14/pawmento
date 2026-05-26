import SwiftUI

struct TodayLogGrid: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today")
                    .font(.headlineMD)
                    .foregroundColor(.onBackground)
                
                Spacer()
                
                Button(action: {
                    // Log action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Log")
                            .font(.labelMD)
                    }
                    .foregroundColor(.onPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primary)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .overlay(
                        Capsule()
                            .stroke(Color.primaryFixedDim.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            HStack(spacing: 12) {
                // Logged Item 1
                LogItemCard(
                    icon: "🥣",
                    title: "Breakfast",
                    subtitle: "7:32am",
                    subtitleIcon: "checkmark.circle.fill",
                    isLogged: true
                )
                
                // Logged Item 2
                LogItemCard(
                    icon: "💊",
                    title: "Apoquel",
                    subtitle: "7:35am",
                    subtitleIcon: "checkmark.circle.fill",
                    isLogged: true
                )
                
                // Due Item 3
                LogItemCard(
                    icon: "🚶",
                    title: "Walk",
                    subtitle: "Due 5pm",
                    subtitleIcon: "clock",
                    isLogged: false
                )
            }
        }
    }
}

struct LogItemCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let subtitleIcon: String
    let isLogged: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(icon)
                .font(.system(size: 24))
                .grayscale(isLogged ? 0 : 1.0)
                .opacity(isLogged ? 1.0 : 0.5)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.labelMD)
                    .foregroundColor(isLogged ? .onPrimaryContainer : .onSurface)
                
                HStack(spacing: 2) {
                    Image(systemName: subtitleIcon)
                        .font(.system(size: 12))
                    Text(subtitle)
                        .font(.labelSM)
                }
                .foregroundColor(isLogged ? Color.primary.opacity(0.8) : .outline)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fill)
        .background(isLogged ? Color.primaryContainer.opacity(0.4) : Color.surfaceBright)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isLogged ? Color.clear : Color.surfaceContainerLow, lineWidth: 1)
        )
        .warmShadow()
    }
}

#Preview {
    TodayLogGrid()
        .padding()
        .background(Color.background)
}
