import SwiftUI

struct FullTimelineView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var logStore: LogStore
    
    @State private var displayCount = 10
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()
                
                if logStore.logs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.tertiaryText)
                        
                        Text("Your timeline is empty.")
                            .font(.headlineSM)
                            .foregroundColor(.primaryText)
                        
                        Text("Tap the + button to start logging.")
                            .font(.bodyMD)
                            .foregroundColor(.secondaryText)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(logStore.logs.prefix(displayCount)) { log in
                                TimelineItemRow(log: log)
                            }
                            
                            if displayCount < logStore.logs.count {
                                Button(action: {
                                    withAnimation {
                                        displayCount += 10
                                    }
                                }) {
                                    Text("See More")
                                        .font(.labelSemibold)
                                        .foregroundColor(.warmTan)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.warmSand, lineWidth: 1)
                                        )
                                }
                                .padding(.top, 16)
                                .padding(.bottom, 32)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Full Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.bodyMD)
                    .foregroundColor(.warmTan)
                }
            }
        }
    }
}

struct TimelineItemRow: View {
    let log: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(log.category.emoji)
                .font(.system(size: 24))
                .frame(width: 48, height: 48)
                .background(Color.primaryContainer)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(log.category.rawValue) logged")
                        .font(.labelMD)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text(formatTime(log.recordedAt))
                        .font(.labelSM)
                        .foregroundColor(.secondaryText)
                }
                
                if let severity = log.severity {
                    Text("Severity: \(severity)/5")
                        .font(.labelSM)
                        .foregroundColor(.warmCoral)
                }
                
                if let note = log.note, !note.isEmpty {
                    Text(note)
                        .font(.bodyMD)
                        .foregroundColor(.secondaryText)
                        .padding(.top, 2)
                        .lineLimit(3)
                }
                
                if let photo = log.photoImage {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 8)
                }
            }
            .padding(.top, 4)
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
