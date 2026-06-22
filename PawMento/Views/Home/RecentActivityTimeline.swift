import SwiftUI

struct RecentActivityTimeline: View {
    @EnvironmentObject var logStore: LogStore
    @State private var showFullTimeline = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent activity")
                .font(.headlineSM)
                .foregroundColor(.onBackground)
            
            ZStack(alignment: .topLeading) {
                if logStore.logs.isEmpty {
                    Text("No logs yet. Tap the + button to log your first activity!")
                        .font(.bodyMD)
                        .foregroundColor(.secondaryText)
                        .padding(.vertical, 20)
                } else {
                    // Vertical Line
                    Rectangle()
                        .fill(Color.surfaceContainerHighest)
                        .frame(width: 2)
                        .padding(.leading, 19)
                        .padding(.vertical, 8)
                    
                    VStack(spacing: 20) {
                        ForEach(logStore.logs.prefix(3)) { log in
                            TimelineItem(
                                iconText: log.category.emoji,
                                title: log.note ?? "Logged activity",
                                time: formatTime(log.recordedAt)
                            )
                        }
                    }
                }
            }
            
            if !logStore.logs.isEmpty {
                Button(action: {
                    showFullTimeline = true
                }) {
                    HStack {
                        Text("See full timeline")
                            .font(.labelMD)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.warmCream)
                    .cornerRadius(12)
                }
                .accessibilityLabel("See full timeline")
                .accessibilityHint("Opens your complete logging history")
            }
        }
        .padding(20)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(24)
        .warmShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recent activity. \(logStore.logs.count) logs available. Double tap to see full timeline.")
        .accessibilityAction {
            showFullTimeline = true
        }
        .sheet(isPresented: $showFullTimeline) {
            FullTimelineView()
                .presentationDragIndicator(.visible)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today,' h:mma"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday,' h:mma"
        } else {
            formatter.dateFormat = "MMM d, h:mma"
        }
        return formatter.string(from: date).lowercased()
    }
}

struct TimelineItem: View {
    let iconText: String
    let title: String
    let time: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Text(iconText)
                .font(.system(size: 18))
                .frame(width: 40, height: 40)
                .background(Color.primaryContainer)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.surfaceContainerLowest, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.labelMD)
                    .foregroundColor(.onSurface)
                Text(time)
                    .font(.labelSM)
                    .foregroundColor(.outline)
            }
            .padding(.top, 4)
            
            Spacer()
        }
    }
}

#Preview {
    RecentActivityTimeline()
        .padding()
        .background(Color.background)
}
