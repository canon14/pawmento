import SwiftUI

// MARK: - View Models & Helpers
enum TimelineBucket: Equatable, Hashable {
    case today
    case yesterday
    case thisWeek
    case earlierThisMonth
    case monthYear(String)
    
    var title: String {
        switch self {
        case .today: return "TODAY"
        case .yesterday: return "YESTERDAY"
        case .thisWeek: return "THIS WEEK"
        case .earlierThisMonth: return "EARLIER THIS MONTH"
        case .monthYear(let str): return str.uppercased()
        }
    }
}

struct BucketGroup: Identifiable {
    let id = UUID()
    let bucket: TimelineBucket
    let headerSubtitle: String?
    let logs: [LogEntry]
}

// MARK: - FullTimelineView
struct FullTimelineView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var petStore: PetStore
    
    // State
    @State private var selectedFilter: String = "All"
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var showFilterSheet: Bool = false
    @State private var expandedBuckets: Set<TimelineBucket> = []
    
    // AI Banner Mock State
    @State private var showBanner: Bool = true
    @State private var bannerPermanentlyDismissed: Bool = false
    
    @State private var expandedImage: UIImage? = nil
    
    let filterOptions = ["All", "Symptoms", "Meals", "Meds", "Walks", "Sleep", "Notes", "Vet visits"]
    
    // Computed Properties
    private var filteredLogs: [LogEntry] {
        var result = logStore.logs
        
        // Category Filter
        if selectedFilter != "All" {
            result = result.filter { log in
                switch selectedFilter {
                case "Symptoms": return log.category == .symptom
                case "Meals": return log.category == .meal || log.category == .water
                case "Meds": return log.category == .med
                case "Walks": return log.category == .walk
                case "Sleep": return log.category == .sleep
                case "Notes": return log.category == .other // approximate mapping
                case "Vet visits": return log.category == .vetVisit
                default: return true
                }
            }
        }
        
        // Search Filter
        if !searchQuery.isEmpty {
            let lowerQuery = searchQuery.lowercased()
            result = result.filter {
                $0.category.rawValue.lowercased().contains(lowerQuery) ||
                ($0.note?.lowercased().contains(lowerQuery) ?? false)
            }
        }
        
        return result
    }
    
    private var bucketedLogs: [BucketGroup] {
        var groups: [TimelineBucket: [LogEntry]] = [:]
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: today))!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        for log in filteredLogs {
            let logDate = cal.startOfDay(for: log.recordedAt)
            var bucket: TimelineBucket
            var sortKey = 0
            
            if logDate == today {
                bucket = .today
            } else if logDate == yesterday {
                bucket = .yesterday
            } else if logDate >= startOfWeek {
                bucket = .thisWeek
            } else if logDate >= startOfMonth {
                bucket = .earlierThisMonth
            } else {
                bucket = .monthYear(formatter.string(from: logDate))
            }
            
            groups[bucket, default: []].append(log)
        }
        
        // Sort buckets chronologically descending
        let sortedBuckets: [TimelineBucket] = [
            .today, .yesterday, .thisWeek, .earlierThisMonth
        ] + groups.keys.filter { 
            if case .monthYear = $0 { return true }
            return false 
        }.sorted { a, b in
            // Just simple reverse string sort for Month Year MVP
            a.title > b.title
        }
        
        let dFormatter = DateFormatter()
        dFormatter.dateFormat = "EEE MMM d"
        
        return sortedBuckets.compactMap { bucket in
            guard let logs = groups[bucket] else { return nil }
            
            var subtitle: String? = nil
            if bucket == .today { subtitle = dFormatter.string(from: Date()) }
            if bucket == .yesterday { subtitle = dFormatter.string(from: cal.date(byAdding: .day, value: -1, to: Date())!) }
            
            // Sort logs within bucket newest first
            let sortedLogs = logs.sorted { $0.recordedAt > $1.recordedAt }
            return BucketGroup(bucket: bucket, headerSubtitle: subtitle, logs: sortedLogs)
        }
    }
    
    private var lastLoggedTimeText: String {
        guard let last = logStore.logs.first else { return "No logs yet" }
        let diff = Int(Date().timeIntervalSince(last.recordedAt) / 3600)
        if diff == 0 { return "last logged just now" }
        return "last logged \(diff)h ago"
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1.1 Nav Bar
                navBar
                
                if filteredLogs.isEmpty && logStore.logs.isEmpty {
                    emptyStateNewPet
                } else if filteredLogs.isEmpty {
                    emptyStateFilter
                } else {
                    // Main Scroll Content
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            
                            // 1.2 Title Block
                            titleBlock
                            
                            // 1.3 AI Pattern Banner
                            if showBanner && !bannerPermanentlyDismissed {
                                aiPatternBanner
                            }
                            
                            // 1.4 Filter Chip Row
                            filterChipRow
                            
                            // 1.5 Timeline Buckets
                            ForEach(bucketedLogs) { group in
                                Section(header: stickyHeader(group: group)) {
                                    bucketContent(group: group)
                                }
                            }
                            
                            // 1.11 Footer CTA
                            if filteredLogs.count >= 7 {
                                footerCTA
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            
            // Full Screen Image Overlay
            if let image = expandedImage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                }
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedImage = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - UI Components
    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.ink900)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(petStore.activePet?.name ?? "Pet")
                .font(.bodySSemibold)
                .foregroundColor(.ink900)
            
            Spacer()
            
            HStack(spacing: 4) {
                Button(action: {
                    withAnimation { isSearching.toggle() }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.ink900)
                        .frame(width: 44, height: 44)
                }
                
                Button(action: { showFilterSheet = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 24))
                            .foregroundColor(.ink900)
                            .frame(width: 44, height: 44)
                        
                        if selectedFilter != "All" {
                            Circle()
                                .fill(Color.coral500)
                                .frame(width: 6, height: 6)
                                .offset(x: -8, y: 8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 44)
        .background(Color.surface0)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(Color.ink200.opacity(0.4)),
            alignment: .bottom
        )
    }
    
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSearching {
                TextField("Search events, notes...", text: $searchQuery)
                    .font(.bodyLG)
                    .padding(12)
                    .background(Color.surface1)
                    .cornerRadius(12)
                    .padding(.top, 8)
            } else {
                Text("Timeline")
                    .font(.displayM)
                    .foregroundColor(.ink900)
                
                Text("\(logStore.logs.count) events · \(lastLoggedTimeText)")
                    .font(.caption)
                    .foregroundColor(.ink600)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var aiPatternBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(.sage700)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pattern detected")
                        .font(.bodySSemibold)
                        .foregroundColor(.sage700)
                    Spacer()
                    Text("Premium")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.sage700)
                        .clipShape(Capsule())
                }
                
                Text("Limping appeared 3× in 10 days — all evenings.")
                    .font(.bodyS)
                    .foregroundColor(.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: { /* Deep dive */ }) {
                    Text("See deep dive ›")
                        .font(.bodySSemibold)
                        .foregroundColor(.sage700)
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(Color.sage50)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sage200, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    private var filterChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { option in
                    let isActive = selectedFilter == option
                    
                    Button(action: {
                        withAnimation {
                            if isActive && option != "All" {
                                selectedFilter = "All"
                            } else {
                                selectedFilter = option
                            }
                        }
                    }) {
                        Text(option)
                            .font(isActive ? .bodySMedium : .bodyS)
                            .padding(.horizontal, 14)
                            .frame(height: 32)
                            .background(isActive ? Color.ink900 : Color.surface1)
                            .foregroundColor(isActive ? Color.surface0 : Color.ink700)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isActive ? Color.clear : Color.ink200, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 44)
        .padding(.bottom, 12)
    }
    
    private func stickyHeader(group: BucketGroup) -> some View {
        HStack {
            // "─── TODAY · Mon Mar 17 ───"
            Rectangle().frame(height: 1).foregroundColor(.ink200)
            
            HStack(spacing: 4) {
                Text(group.bucket.title)
                    .font(.captionSemibold)
                    .tracking(0.5)
                if let sub = group.headerSubtitle {
                    Text("· \(sub)")
                        .font(.captionSemibold)
                        .tracking(0.5)
                }
            }
            .foregroundColor(.ink600)
            .layoutPriority(1)
            
            Rectangle().frame(height: 1).foregroundColor(.ink200)
        }
        .padding(.horizontal, 20)
        .frame(height: 32)
        .background(
            Color.surface0.opacity(0.96)
                .background(Material.ultraThinMaterial)
        )
    }
    
    private func bucketContent(group: BucketGroup) -> some View {
        VStack(spacing: 12) {
            let isExpanded = expandedBuckets.contains(group.bucket)
            // Smart collapse rules: Expand Today & Yesterday by default. 
            // Older buckets collapse if > 5 items.
            let autoCollapse = group.bucket != .today && group.bucket != .yesterday
            let shouldCollapse = autoCollapse && group.logs.count > 5 && !isExpanded
            
            let visibleLogs = shouldCollapse ? Array(group.logs.prefix(5)) : group.logs
            
            ForEach(visibleLogs) { log in
                TimelineItemRowV2(log: log, expandedImage: $expandedImage)
            }
            
            if shouldCollapse {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        _ = expandedBuckets.insert(group.bucket)
                    }
                }) {
                    Text("\(group.logs.count - 5) more events collapsed — Tap to expand")
                        .font(.bodySMedium)
                        .foregroundColor(.sage700)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
    
    private var footerCTA: some View {
        Button(action: { print("Vet PDF requested") }) {
            HStack {
                Text(selectedFilter == "All" ? "Export this month as Vet PDF" : "Export filtered view as PDF")
                    .font(.bodySSemibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Premium")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color.ink900)
            .cornerRadius(14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    private var emptyStateNewPet: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "pawprint.circle")
                .font(.system(size: 64))
                .foregroundColor(.ink300)
            
            Text("\(petStore.activePet?.name ?? "Your pet")'s timeline starts here. Log your first symptom, meal, or walk to begin building their health story.")
                .font(.bodyMD)
                .foregroundColor(.ink600)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var emptyStateFilter: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 64))
                .foregroundColor(.ink300)
            
            Text("No \(selectedFilter.lowercased()) events in this range.")
                .font(.bodyMD)
                .foregroundColor(.ink600)
                .multilineTextAlignment(.center)
            
            Button("Clear filter") {
                withAnimation { selectedFilter = "All" }
            }
            .font(.bodySSemibold)
            .foregroundColor(.sage700)
            .padding(.top, 8)
            
            Spacer()
        }
    }
}

// MARK: - TimelineItemRowV2
struct TimelineItemRowV2: View {
    let log: LogEntry
    @Binding var expandedImage: UIImage?
    
    @State private var isPressed = false
    
    var isSymptom: Bool { log.category == .symptom }
    
    var severityColor: Color {
        guard let s = log.severity else { return .sage }
        switch s {
        case 1, 2: return .sage
        case 3: return .amber
        case 4: return .coral500
        case 5: return .red500
        default: return .sage
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // Left Column: Glyph
            glyph
                .frame(width: 32)
            
            // Middle Column: Content
            VStack(alignment: .leading, spacing: 4) {
                // Title Line
                let title = log.note?.isEmpty == false && !isSymptom ? log.note! : log.category.rawValue
                Text(isSymptom ? "\(log.category.rawValue) — Symptom" : title)
                    .font(.bodySSemibold)
                    .foregroundColor(.ink900)
                    .lineLimit(1)
                
                // Pattern Badge (Mock condition)
                if isSymptom {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 10))
                        Text("3rd time this month")
                    }
                    .font(.captionSemibold)
                    .foregroundColor(.sage700)
                }
                
                // Note
                if let note = log.note, !note.isEmpty, isSymptom {
                    Text(note)
                        .font(.bodyS)
                        .foregroundColor(.ink700)
                        .lineLimit(2)
                }
                
                // Photo
                if let photo = log.photoImage {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { expandedImage = photo }
                    }) {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ink100, lineWidth: 1))
                            .padding(.top, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer(minLength: 8)
            
            // Right Column: Timestamp
            Text(timeFormatter.string(from: log.recordedAt).lowercased())
                .font(.captionTabular)
                .foregroundColor(.ink500)
                .padding(.top, 2)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(isPressed ? Color.surface1 : Color.surface0)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink100, lineWidth: 1))
        .onTapGesture {
            // Open symptom detail or category sheet
            print("Tapped log: \(log.category.rawValue)")
        }
        ._onButtonGesture { pressing in
            withAnimation(.easeIn(duration: 0.05)) { isPressed = pressing }
        } perform: {}
    }
    
    @ViewBuilder
    private var glyph: some View {
        ZStack(alignment: .bottomTrailing) {
            if isSymptom {
                Circle()
                    .fill(severityColor)
                    .frame(width: 32, height: 32)
                
                Text(log.category.emoji)
                    .font(.system(size: 16))
            } else {
                Circle()
                    .stroke(Color.ink500, lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                
                Text(log.category.emoji)
                    .font(.system(size: 16))
            }
            
            if log.photoImage != nil {
                Image(systemName: "camera.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Color.ink900)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mma"
        return f
    }
}
