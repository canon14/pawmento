import SwiftUI

// MARK: - FullTimelineView
struct FullTimelineView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var petStore: PetStore
    
    @StateObject private var viewModel = FullTimelineViewModel()
    @StateObject private var insightsVM = InsightsViewModel()
    
    // State
    @State private var isSearching: Bool = false
    @State private var showFilterSheet: Bool = false
    @State private var expandedBuckets: Set<TimelineBucket> = []
    
    @State private var expandedImage: UIImage? = nil
    @State private var selectedLog: LogEntry? = nil
    @State private var showPaywall = false
    
    let filterOptions = ["All", "Symptoms", "Meals", "Meds", "Walks", "Sleep", "Notes", "Vet visits"]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1.1 Nav Bar
                navBar
                
                if viewModel.filteredLogs.isEmpty && logStore.logs.isEmpty {
                    emptyStateNewPet
                } else if viewModel.filteredLogs.isEmpty {
                    emptyStateFilter
                } else {
                    // Main Scroll Content
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            
                            // 1.2 Title Block
                            titleBlock
                            
                            // 1.3 AI Pattern Banner
                            if viewModel.showBanner && !viewModel.bannerPermanentlyDismissed {
                                if let heroInsight = insightsVM.heroInsight {
                                    aiPatternBanner(insight: heroInsight)
                                }
                            }
                            
                            // 1.4 Filter Chip Row
                            filterChipRow
                            
                            // 1.5 Timeline Buckets
                            ForEach(viewModel.bucketedLogs) { group in
                                Section(header: stickyHeader(group: group)) {
                                    bucketContent(group: group)
                                }
                            }
                            
                            // 1.11 Footer CTA
                            if viewModel.filteredLogs.count >= 7 {
                                footerCTA
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            
            // Full Screen Image Overlay with Pinch-to-Zoom & Close
            if let image = expandedImage {
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            // Frame allows dragging within ScrollView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .ignoresSafeArea()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { expandedImage = nil }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.displayMD)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .padding(.top, 30) // Safety for notch
                    }
                    .accessibilityLabel("Close photo")
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedLog) { log in
            LogDetailSheet(existingLog: log)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(featureContext: "Timeline Export")
        }
        .onAppear {
            viewModel.ingest(logs: logStore.logs)
            Task {
                await insightsVM.loadInsights(for: petStore.activePet)
            }
        }
        .onReceive(logStore.$logs) { newLogs in
            viewModel.ingest(logs: newLogs)
        }
    }
    
    // MARK: - UI Components
    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.headlineLG)
                    .foregroundColor(.ink900)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(petStore.activePet?.name ?? "Pet")
                .font(.labelSM)
                .foregroundColor(.ink900)
            
            Spacer()
            
            HStack(spacing: 4) {
                Button(action: {
                    withAnimation { isSearching.toggle() }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.headlineLG)
                        .foregroundColor(.ink900)
                        .frame(width: 44, height: 44)
                }
                
                Button(action: { showFilterSheet = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.headlineLG)
                            .foregroundColor(.ink900)
                            .frame(width: 44, height: 44)
                        
                        if viewModel.selectedFilter != "All" {
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
                TextField("Search events, notes...", text: $viewModel.searchQuery)
                    .font(.bodyLG)
                    .padding(12)
                    .background(Color.surface1)
                    .cornerRadius(AppRadius.input)
                    .padding(.top, 8)
            } else {
                Text("Timeline")
                    .font(.displaySM)
                    .foregroundColor(.ink900)
                
                Text("\(logStore.logs.count) events · \(viewModel.lastLoggedTimeText)")
                    .font(.caption)
                    .foregroundColor(.ink600)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private func aiPatternBanner(insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.tier.iconName)
                .font(.headlineLG)
                .foregroundColor(.sage700)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.tier.label.capitalized)
                        .font(.labelSM)
                        .foregroundColor(.sage700)
                    Spacer()
                    if insight.isPremiumGated {
                        Text("Premium")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.sage700)
                            .clipShape(Capsule())
                    }
                }
                
                Text(insight.headline)
                    .font(.bodySM)
                    .foregroundColor(.ink900)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: { showPaywall = true }) {
                    Text("See deep dive ›")
                        .font(.labelSM)
                        .foregroundColor(.sage700)
                        .padding(.top, 2)
                }
            }
        }
        .padding(16)
        .background(Color.sage50)
        .cornerRadius(AppRadius.input)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sage200, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    private var filterChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { option in
                    let isActive = viewModel.selectedFilter == option
                    
                    Button(action: {
                        withAnimation {
                            if isActive && option != "All" {
                                viewModel.selectedFilter = "All"
                            } else {
                                viewModel.selectedFilter = option
                            }
                        }
                    }) {
                        Text(option)
                            .font(isActive ? .labelMD : .bodySM)
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
            Rectangle().frame(height: 1).foregroundColor(.ink200)
            
            HStack(spacing: 4) {
                Text(group.bucket.title)
                    .font(.labelXS)
                    .tracking(0.5)
                if let sub = group.headerSubtitle {
                    Text("· \(sub)")
                        .font(.labelXS)
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
            let autoCollapse = group.bucket != .today && group.bucket != .yesterday
            let shouldCollapse = autoCollapse && group.logs.count > 5 && !isExpanded
            
            let visibleLogs = shouldCollapse ? Array(group.logs.prefix(5)) : group.logs
            
            ForEach(visibleLogs) { log in
                TimelineItemRowV2(
                    log: log,
                    badgeText: viewModel.getInsightBadge(for: log),
                    expandedImage: $expandedImage
                ) {
                    selectedLog = log
                }
            }
            
            if shouldCollapse {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        _ = expandedBuckets.insert(group.bucket)
                    }
                }) {
                    Text("\(group.logs.count - 5) more events collapsed — Tap to expand")
                        .font(.labelMD)
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
        Button(action: { showPaywall = true }) {
            HStack {
                Text(viewModel.selectedFilter == "All" ? "Export this month as Vet PDF" : "Export filtered view as PDF")
                    .font(.labelSM)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Premium")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.surface0.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color.ink900)
            .cornerRadius(AppRadius.input)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    private var emptyStateNewPet: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "pawprint.circle")
                .font(.displayLG)
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
                .font(.displayLG)
                .foregroundColor(.ink300)
            
            Text("No \(viewModel.selectedFilter.lowercased()) events in this range.")
                .font(.bodyMD)
                .foregroundColor(.ink600)
                .multilineTextAlignment(.center)
            
            Button("Clear filter") {
                withAnimation { viewModel.selectedFilter = "All" }
            }
            .font(.labelSM)
            .foregroundColor(.sage700)
            .padding(.top, 8)
            
            Spacer()
        }
    }
}

// MARK: - ScaleButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.surface1 : Color.surface0)
            .cornerRadius(AppRadius.input)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.ink100, lineWidth: 1))
            .animation(.easeIn(duration: 0.05), value: configuration.isPressed)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - TimelineItemRowV2
struct TimelineItemRowV2: View {
    let log: LogEntry
    let badgeText: String?
    @Binding var expandedImage: UIImage?
    var onTap: (() -> Void)? = nil
    
    var isSymptom: Bool { log.category == .symptom }
    
    var severityColor: Color {
        guard let s = log.severity else { return .primary }
        switch s {
        case 1, 2: return .primary
        case 3: return .amber
        case 4: return .coral500
        case 5: return .red500
        default: return .primary
        }
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(alignment: .top, spacing: 12) {
                
                // Left Column: Glyph
                glyph
                    .frame(width: 32)
                
                // Middle Column: Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title Line
                    let title = log.note?.isEmpty == false && !isSymptom ? log.note! : log.category.rawValue
                    Text(isSymptom ? "\(log.category.rawValue) — Symptom" : title)
                        .font(.labelSM)
                        .foregroundColor(.ink900)
                        .lineLimit(1)
                    
                    // Dynamic Pattern Badge
                    if isSymptom, let badge = badgeText {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                            Text(badge)
                        }
                        .font(.labelXS)
                        .foregroundColor(.sage700)
                    }
                    
                    // Note
                    if let note = log.note, !note.isEmpty, isSymptom {
                        Text(note)
                            .font(.bodySM)
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
                Text(log.recordedAt.formatted(date: .omitted, time: .shortened).lowercased())
                    .font(.captionTabular)
                    .foregroundColor(.ink500)
                    .padding(.top, 2)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private var glyph: some View {
        ZStack(alignment: .bottomTrailing) {
            if isSymptom {
                Circle()
                    .fill(severityColor)
                    .frame(width: 32, height: 32)
                
                Text(log.category.emoji)
                    .font(.bodyMD)
            } else {
                Circle()
                    .stroke(Color.ink500, lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                
                Text(log.category.emoji)
                    .font(.bodyMD)
            }
            
            if log.photoImage != nil {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Color.ink900)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
        }
    }
}
