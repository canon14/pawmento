import SwiftUI

struct TodayLogGridItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let subtitleIcon: String
    let isLogged: Bool
}

struct TodayLogGrid: View {
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var medicationStore: MedicationStore
    var onLogAction: () -> Void = {}
    
    private var gridItems: [TodayLogGridItem] {
        var items: [TodayLogGridItem] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        
        let todayLogs = logStore.logs.filter { Calendar.current.isDateInToday($0.recordedAt) }
        
        // 1. Add recent logs from today
        for log in todayLogs.prefix(3) {
            let title = log.note?.isEmpty == false ? log.note! : log.category.rawValue
            items.append(TodayLogGridItem(
                icon: log.category.emoji,
                title: title,
                subtitle: formatter.string(from: log.recordedAt).lowercased(),
                subtitleIcon: "checkmark.circle.fill",
                isLogged: true
            ))
        }
        
        // 2. Add due medications if we don't have 3 items
        if items.count < 3 {
            for med in medicationStore.medications {
                if let due = med.nextDueDate, Calendar.current.isDateInToday(due) {
                    items.append(TodayLogGridItem(
                        icon: "💊",
                        title: med.name,
                        subtitle: "Due \(formatter.string(from: due).lowercased())",
                        subtitleIcon: "clock",
                        isLogged: false
                    ))
                    if items.count >= 3 { break }
                }
            }
        }
        
        // 3. Fallbacks if completely empty
        if items.isEmpty {
            items.append(TodayLogGridItem(icon: "🥣", title: "Breakfast", subtitle: "Log me!", subtitleIcon: "plus.circle", isLogged: false))
            items.append(TodayLogGridItem(icon: "🚶", title: "Walk", subtitle: "Log me!", subtitleIcon: "plus.circle", isLogged: false))
        }
        
        return Array(items.prefix(3))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today")
                    .font(.headlineMD)
                    .foregroundColor(.onBackground)
                
                Spacer()
                
                Button(action: onLogAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.bodyMD)
                        Text("Log")
                            .font(.labelMD)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            HStack(spacing: 12) {
                ForEach(gridItems) { item in
                    Button(action: {
                        if !item.isLogged {
                            onLogAction()
                        }
                    }) {
                        LogItemCard(
                            icon: item.icon,
                            title: item.title,
                            subtitle: item.subtitle,
                            subtitleIcon: item.subtitleIcon,
                            isLogged: item.isLogged
                        )
                    }
                    .buttonStyle(SquishyCardStyle())
                }
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
                .font(.system(size: 32))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                .grayscale(isLogged ? 0 : 1.0)
                .opacity(isLogged ? 1.0 : 0.5)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.labelMD)
                    .foregroundColor(isLogged ? .onPrimaryContainer : .onSurface)
                
                HStack(spacing: 2) {
                    Image(systemName: subtitleIcon)
                        .font(.caption)
                    Text(subtitle)
                        .font(.labelSM)
                }
                .foregroundColor(isLogged ? Color.primary.opacity(0.8) : .outline)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fill)
        .background(
            Group {
                if isLogged {
                    LinearGradient(colors: [Color.primaryContainer.opacity(0.6), Color.primaryContainer.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                } else {
                    Color.surfaceBright
                }
            }
        )
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(isLogged ? Color.primary.opacity(0.2) : Color.outline.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: isLogged ? [] : [4]))
        )
        .warmShadow()
    }
}

#Preview {
    TodayLogGrid()
        .padding()
        .background(Color.background)
}
