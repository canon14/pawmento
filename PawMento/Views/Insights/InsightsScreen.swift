import SwiftUI

struct InsightsScreen: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @StateObject private var viewModel = InsightsViewModel()
    @State private var selectedInsight: Insight?
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                timeRangeChips
                
                mainContent
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.loadInsights(for: petStore.activePet)
                }
            }
            .onChange(of: petStore.activePet?.id) { _, _ in
                Task {
                    await viewModel.loadInsights(for: petStore.activePet, forceRefresh: true)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.ink900)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 12))
                        Text(petStore.activePet?.name ?? "Buddy")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.ink900)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Toggle premium for dev testing
                        viewModel.isPremium.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.ink900)
                    }
                }
            }
        }
    }
    
    private var timeRangeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        Task { await viewModel.changeTimeRange(to: range, for: petStore.activePet) }
                    }) {
                        Text(range.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 14)
                            .frame(height: 32)
                            .background(viewModel.timeRange == range ? Color.ink900 : Color(hex: "F7F9F9"))
                            .foregroundColor(viewModel.timeRange == range ? .white : Color.ink900.opacity(0.8))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(viewModel.timeRange == range ? Color.clear : Color.ink900.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
        .frame(height: 44)
        .background(Color.white)
    }
    
    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                switch viewModel.viewState {
                case .loading:
                    ProgressView()
                        .padding(.top, 40)
                case .success:
                    heroSection
                    patternsSection
                    benchmarkSection
                    askCoachSection
                default:
                    // All other states (noData, offline, error)
                    InsightEmptyStateView(state: viewModel.viewState) {
                        handleEmptyStateAction(viewModel.viewState)
                    }
                    benchmarkSection
                    askCoachSection
                }
            }
            .padding(20)
            .padding(.bottom, 60)
        }
        .refreshable {
            await viewModel.refreshInsights(for: petStore.activePet)
        }
        .navigationDestination(item: $selectedInsight) { insight in
            InsightDetailScreen(insight: insight)
        }
        .sheet(isPresented: $showPaywall) {
            if let insight = selectedInsight {
                PaywallSheet(insight: insight)
            }
        }
    }
    
    private func handleEmptyStateAction(_ state: InsightsViewModel.ViewState) {
        switch state {
        case .noDataForRange:
            Task { await viewModel.changeTimeRange(to: .all, for: petStore.activePet) }
        case .offline, .error:
            Task { await viewModel.refreshInsights(for: petStore.activePet) }
        case .noData:
            dismiss() // Let them go back to Home to log
        case .noPatterns:
            // Could pop open the Coach sheet, for now just print
            print("Open Coach Sheet")
        default:
            break
        }
    }
    
    @ViewBuilder
    private var heroSection: some View {
        if let hero = viewModel.heroInsight {
            VStack(alignment: .leading, spacing: 12) {
                Text("─── THIS WEEK'S HEADLINE ───")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.ink900.opacity(0.6))
                    .kerning(0.5)
                
                HeroInsightCard(insight: hero, isPremium: viewModel.isPremium, onActionTapped: { action in
                    print("Tapped \(action.title)")
                }, onCardTapped: {
                    if hero.isPremiumGated && !viewModel.isPremium {
                        selectedInsight = hero
                        showPaywall = true
                    } else {
                        selectedInsight = hero
                    }
                })
            }
        }
    }
    
    @ViewBuilder
    private var patternsSection: some View {
        if !viewModel.patternCards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("─── OTHER PATTERNS ───")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.ink900.opacity(0.6))
                    .kerning(0.5)
                
                ForEach(viewModel.patternCards) { insight in
                    PatternCard(insight: insight, isPremium: viewModel.isPremium, onCardTapped: {
                        if insight.isPremiumGated && !viewModel.isPremium {
                            selectedInsight = insight
                            showPaywall = true
                        } else {
                            selectedInsight = insight
                        }
                    })
                }
            }
        }
    }
    
    @ViewBuilder
    private var benchmarkSection: some View {
        if let benchmark = viewModel.breedBenchmark {
            VStack(alignment: .leading, spacing: 12) {
                Text("─── HEALTH BENCHMARKS ───")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.ink900.opacity(0.6))
                    .kerning(0.5)
                
                BreedBenchmarkCard(benchmark: benchmark, isPremium: viewModel.isPremium, onCardTapped: {
                    print("Tapped Benchmark Card")
                })
            }
        }
    }
    
    private var askCoachSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("─── ASK \(petStore.activePet?.name.uppercased() ?? "BUDDY'S") AI COACH ───")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.ink900.opacity(0.6))
                .kerning(0.5)
            
            AskCoachInsightCard(suggestions: viewModel.coachSuggestions, onChatTapped: {
                print("Open Chat from Insights")
            }, onSuggestionTapped: { suggestion in
                print("Send: \(suggestion)")
            })
        }
    }
}
