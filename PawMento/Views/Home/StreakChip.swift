import SwiftUI

struct StreakChip: View {
    var streak: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streak >= 1 ? "flame.fill" : "flame")
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.labelSM)
        }
        .foregroundColor(streak >= 1 ? .primary : .onSurfaceVariant)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(streak >= 1 ? Color.primary.opacity(0.10) : Color.surfaceContainer)
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(streak >= 1 ? 0.18 : 0.08), lineWidth: 1)
        )
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var label: String {
        switch streak {
        case 0:
            return "Start a streak"
        case 1:
            return "1-day streak"
        default:
            return "\(streak)-day streak"
        }
    }
    
    private var accessibilityLabel: String {
        switch streak {
        case 0:
            return "No logging streak yet. Start a streak by logging today."
        case 1:
            return "1 day logging streak"
        default:
            return "\(streak) day logging streak"
        }
    }
}

#Preview("Streak 0") {
    StreakChip(streak: 0)
        .padding()
        .background(Color.background)
}

#Preview("Streak 1") {
    StreakChip(streak: 1)
        .padding()
        .background(Color.background)
}

#Preview("Streak 3") {
    StreakChip(streak: 3)
        .padding()
        .background(Color.background)
}
