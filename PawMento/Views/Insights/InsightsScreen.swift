import SwiftUI

struct InsightsScreen: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var toastManager: ToastManager
    @StateObject private var viewModel = InsightsViewModel()
    @State private var selectedInsight: Insight?
    @State private var paywallInsight: Insight?
    @State private var showPaywall = false
    @State private var paywallFeatureContext: String? = nil
    @State private var showCoachChat = false
    @State private var showBreedBenchmarkDetail = false
    @State private var showShareSheet = false
    @State private var shareInsight: Insight?
    @State private var showEventPaywall = false
    @State private var eventPaywallInsight: Insight?
    
    @EnvironmentObject var coachViewModel: CoachViewModel
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                timeRangeChips
                
                if petStore.pets.count > 1 {
                    comparePetsChip
                }
                
                mainContent
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.isPremium = coachViewModel.isPremium
                Task {
                    await viewModel.loadInsights(for: petStore.activePet)
                    await checkFirstStrongInsightPaywall()
                }
            }
            .onChange(of: coachViewModel.isPremium) { _, isPremium in
                viewModel.isPremium = isPremium
            }
            .onChange(of: petStore.activePet?.id) { _, _ in
                Task {
                    await viewModel.loadInsights(for: petStore.activePet, forceRefresh: true)
                    await checkFirstStrongInsightPaywall()
                }
            }
            .onChange(of: logStore.logs.count) { _, _ in
                Task {
                    await viewModel.loadInsights(for: petStore.activePet, forceRefresh: true)
                    await checkFirstStrongInsightPaywall()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                            .frame(width: 36, height: 36)
                            .background(Color.surfaceContainer.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                        Text("Insights")
                            .font(.headlineSM)
                            .foregroundColor(.primaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Time Range Chips
    
    private var timeRangeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    let isSelected = viewModel.timeRange == range
                    
                    Button(action: {
                        Task {
                            await viewModel.changeTimeRange(to: range, for: petStore.activePet)
                            await checkFirstStrongInsightPaywall()
                        }
                    }) {
                        timeRangeLabel(range: range, isSelected: isSelected)
                    }
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .frame(height: 50)
        .background(
            Color.surfaceContainerLowest.opacity(0.8)
                .background(.ultraThinMaterial)
        )
    }
    
    private func timeRangeLabel(range: TimeRange, isSelected: Bool) -> some View {
        let bgColor: Color = isSelected ? .primary : .surfaceContainerLowest
        let fgColor: Color = isSelected ? .white : .secondaryText
        let borderColor: Color = isSelected ? .clear : .primary.opacity(0.1)
        let shadowColor: Color = isSelected ? .primary.opacity(0.2) : .clear
        
        return Text(range.rawValue)
            .font(.labelMD)
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(bgColor)
            .foregroundColor(fgColor)
            .cornerRadius(17)
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Compare Pets Chip (🟡 9.2 — was dead button)
    
    private var comparePetsChip: some View {
        Button(action: {
            toastManager.show("Compare Pets coming soon", actionLabel: nil, action: nil)
        }) {
            HStack(spacing: 6) {
                Image(systemName: "square.split.2x1")
                    .font(.system(size: 12))
                Text("Compare with your other pets")
                    .font(.labelMD)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.08))
            .cornerRadius(20)
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.top, 12)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                switch viewModel.viewState {
                case .loading:
                    insightsShimmer
                case .success:
                    heroSection
                    patternsSection
                    benchmarkSection
                    askCoachSection
                default:
                    InsightEmptyStateView(state: viewModel.viewState, petName: petStore.activePet?.name ?? PetStore.fallbackPetName) {
                        handleEmptyStateAction(viewModel.viewState)
                    }
                    askCoachSection
                }
            }
            .padding(20)
            .padding(.bottom, 60)
        }
        .refreshable {
            await viewModel.refreshInsights(for: petStore.activePet)
            await checkFirstStrongInsightPaywall()
        }
        .navigationDestination(item: $selectedInsight) { insight in
            InsightDetailScreen(insight: insight, onActionTapped: { action in
                if action.title.lowercased().contains("coach") || action.title.lowercased().contains("ask") {
                    showCoachChat = true
                    Task {
                        let ownerId = await authManager.getCurrentUserId()
                        await coachViewModel.sendMessage("I'm looking at the insight: '\(insight.headline)'. Can you give me more advice on this?", pet: petStore.activePet, ownerId: ownerId)
                    }
                } else if InsightShareHelper.isShareAction(action.title) {
                    presentShare(for: insight)
                }
            })
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(insight: paywallInsight, featureContext: paywallFeatureContext)
                .onDisappear {
                    paywallInsight = nil
                    paywallFeatureContext = nil
                }
        }
        .sheet(isPresented: $showEventPaywall, onDismiss: {
            eventPaywallInsight = nil
        }) {
            if let insight = eventPaywallInsight {
                PaywallSheet(
                    insight: insight,
                    trigger: .firstStrongInsight,
                    petName: petStore.activePet?.name ?? PetStore.fallbackPetName
                )
            }
        }
        .sheet(isPresented: $showBreedBenchmarkDetail) {
            if let benchmark = viewModel.breedBenchmark {
                BreedBenchmarkDetailScreen(
                    benchmark: benchmark,
                    petName: petStore.activePet?.name ?? PetStore.fallbackPetName,
                    onAskCoach: {
                        showCoachChat = true
                        Task {
                            let ownerId = await authManager.getCurrentUserId()
                            await coachViewModel.sendMessage("Can we talk about my dog's breed benchmarks? They are in the \(benchmark.activityPercentile)th percentile for activity.", pet: petStore.activePet, ownerId: ownerId)
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showCoachChat) {
            CoachChatView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let insight = shareInsight {
                InsightShareSheet(
                    items: [InsightShareHelper.shareText(
                        for: insight,
                        petName: petStore.activePet?.name ?? PetStore.fallbackPetName
                    )]
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Shimmer Loading State (replaces plain ProgressView)
    
    private var insightsShimmer: some View {
        VStack(spacing: 20) {
            // Hero shimmer
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Color.surfaceContainer.opacity(0.5))
                .frame(height: 220)
                .shimmer()
            
            // Pattern card shimmers
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(Color.surfaceContainer.opacity(0.5))
                    .frame(height: 140)
                    .shimmer()
            }
        }
    }
    
    // MARK: - Sections
    
    private func handleEmptyStateAction(_ state: InsightsViewModel.ViewState) {
        switch state {
        case .noDataForRange:
            Task { await viewModel.changeTimeRange(to: .all, for: petStore.activePet) }
        case .offline, .error:
            Task { await viewModel.refreshInsights(for: petStore.activePet) }
        case .noData:
            dismiss() // Let them go back to Home to log
        case .noPatterns:
            showCoachChat = true
        default:
            break
        }
    }
    
    @ViewBuilder
    private var heroSection: some View {
        if let hero = viewModel.heroInsight {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("This Week's Headline", style: .withRule)
                
                HeroInsightCard(insight: hero, isPremium: viewModel.isPremium, petName: petStore.activePet?.name ?? PetStore.fallbackPetName, onActionTapped: { action in
                    if InsightShareHelper.isShareAction(action.title) {
                        presentShare(for: hero)
                    }
                }, onCardTapped: {
                    handleInsightTap(hero)
                })
                .contextMenu {
                    insightContextMenu(for: hero)
                }
            }
        }
    }
    
    @ViewBuilder
    private var patternsSection: some View {
        if !viewModel.patternCards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Other Patterns", style: .withRule)
                
                ForEach(viewModel.patternCards) { insight in
                    PatternCard(insight: insight, isPremium: viewModel.isPremium, onCardTapped: {
                        handleInsightTap(insight)
                    })
                    .contextMenu {
                        insightContextMenu(for: insight)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var benchmarkSection: some View {
        if InsightsViewModel.breedBenchmarksEnabled, let benchmark = viewModel.breedBenchmark {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Health Benchmarks", style: .withRule)
                
                BreedBenchmarkCard(benchmark: benchmark, isPremium: viewModel.isPremium, onCardTapped: {
                    if !viewModel.isPremium {
                        paywallFeatureContext = "Breed Benchmarks"
                        showPaywall = true
                    } else {
                        showBreedBenchmarkDetail = true
                    }
                })
            }
        }
    }
    
    @ViewBuilder
    private var askCoachSection: some View {
        if !viewModel.coachSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Ask \(petStore.activePet?.name ?? PetStore.fallbackPetName)'s AI Coach", style: .withRule)
                
                AskCoachInsightCard(suggestions: viewModel.coachSuggestions, petName: petStore.activePet?.name ?? PetStore.fallbackPetName, onChatTapped: {
                    showCoachChat = true
                }, onSuggestionTapped: { suggestion in
                    showCoachChat = true
                    Task {
                        let ownerId = await authManager.getCurrentUserId()
                        await coachViewModel.sendMessage(suggestion, pet: petStore.activePet, ownerId: ownerId)
                    }
                })
            }
        }
    }
    
    @ViewBuilder
    private func insightContextMenu(for insight: Insight) -> some View {
        Button(action: {
            presentShare(for: insight)
        }) {
            Label("Share Insight", systemImage: "square.and.arrow.up")
        }
        
        Button(action: {
            viewModel.dismissInsight(insight, reason: .resolved, petId: petStore.activePet?.id)
        }) {
            Label("Mark as Resolved", systemImage: "checkmark.circle")
        }
        
        Button(role: .destructive, action: {
            viewModel.dismissInsight(insight, reason: .notRelevant, petId: petStore.activePet?.id)
        }) {
            Label("Not Relevant to \(petStore.activePet?.name ?? PetStore.fallbackPetName)", systemImage: "xmark.circle")
        }
    }
    
    private func handleInsightTap(_ insight: Insight) {
        if insight.isPremiumGated && !viewModel.isPremium {
            // Paywall only — do not set selectedInsight (avoids ungated detail push).
            paywallInsight = insight
            showPaywall = true
        } else {
            selectedInsight = insight
        }
    }
    
    private func presentShare(for insight: Insight) {
        if insight.isPremiumGated && !viewModel.isPremium {
            paywallInsight = insight
            showPaywall = true
            return
        }
        shareInsight = insight
        showShareSheet = true
    }
    
    private func checkFirstStrongInsightPaywall() async {
        guard !viewModel.isPremium else { return }
        guard viewModel.viewState == .success else { return }
        guard let userId = await authManager.getCurrentUserId() else { return }
        
        var insights: [Insight] = []
        if let hero = viewModel.heroInsight {
            insights.append(hero)
        }
        insights.append(contentsOf: viewModel.patternCards)
        
        guard let strong = PaywallEventGate.strongInsight(in: insights) else { return }
        guard PaywallEventGate.claimFirstStrongInsightIfEligible(userId: userId) else { return }
        
        eventPaywallInsight = strong
        showEventPaywall = true
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 300)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
