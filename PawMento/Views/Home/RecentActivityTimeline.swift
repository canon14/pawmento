import SwiftUI

struct RecentActivityTimeline: View {
    @EnvironmentObject var logStore: LogStore
    var petName: String = PetStore.fallbackPetName
    var onLogCTA: (() -> Void)? = nil
    @State private var showFullTimeline = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent activity")
                .font(.headlineSM)
                .foregroundColor(.onBackground)
            
            ZStack(alignment: .topLeading) {
                if logStore.logs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nothing logged yet — tap below to add \(petName)'s first entry.")
                            .font(.bodyMD)
                            .foregroundColor(.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let onLogCTA {
                            Button(action: onLogCTA) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Log an entry")
                                        .font(.labelMD)
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.primary.opacity(0.08))
                                .cornerRadius(AppRadius.sm)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 12)
                } else {
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
                                time: formatTime(log.recordedAt),
                                photoImage: log.photoImage,
                                photoURL: log.photoLocalURL
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
                    .cornerRadius(AppRadius.input)
                }
                .accessibilityLabel("See full timeline")
                .accessibilityHint("Opens your complete logging history")
            }
        }
        .padding(20)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(AppRadius.card)
        .warmShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAction {
            if logStore.logs.isEmpty {
                onLogCTA?()
            } else {
                showFullTimeline = true
            }
        }
        .fullScreenCover(isPresented: $showFullTimeline) {
            FullTimelineView()
                .presentationDragIndicator(.visible)
        }
    }
    
    private var accessibilitySummary: String {
        if logStore.logs.isEmpty {
            return "Recent activity. No logs yet. Double tap to log an entry."
        }
        return "Recent activity. \(logStore.logs.count) logs available. Double tap to see full timeline."
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
    var photoImage: UIImage? = nil
    var photoURL: URL? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Text(iconText)
                .font(.headlineSM)
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
            
            if let uiImage = photoImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if photoURL != nil {
                CachedAsyncImage(url: photoURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    RecentActivityTimeline(petName: "Luna", onLogCTA: {})
        .padding()
        .background(Color.background)
}
