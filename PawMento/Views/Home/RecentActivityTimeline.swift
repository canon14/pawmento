import SwiftUI

struct RecentActivityTimeline: View {
    @EnvironmentObject var logStore: LogStore
    @State private var showFullTimeline = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent activity")
                    .font(.headlineSM)
                    .foregroundColor(.onBackground)
                
                Spacer()
                
                Button(action: {
                    showFullTimeline = true
                }) {
                    Text("See full timeline ›")
                        .font(.labelSM)
                        .foregroundColor(.secondary)
                }
            }
            
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
                                title: "\(log.category.rawValue) logged",
                                time: formatTime(log.recordedAt)
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(24)
        .warmShadow()
        .sheet(isPresented: $showFullTimeline) {
            FullTimelineView()
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
