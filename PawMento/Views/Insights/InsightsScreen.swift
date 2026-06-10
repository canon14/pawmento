import SwiftUI

struct InsightsScreen: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    @StateObject private var viewModel = InsightsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Time Range Chips Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: {
                                viewModel.changeTimeRange(to: range)
                            }) {
                                Text(range.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 14)
                                    .frame(height: 32)
                                    .background(viewModel.timeRange == range ? Color.ink900 : Color(hex: "F7F9F9")) // surface-1
                                    .foregroundColor(viewModel.timeRange == range ? .white : Color.ink900.opacity(0.8)) // ink-700
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
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if viewModel.isAnalyzing {
                            // Simple loading shimmer representation
                            ProgressView()
                                .padding(.top, 40)
                        } else {
                            // Hero Section
                            if let hero = viewModel.heroInsight {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("─── THIS WEEK'S HEADLINE ───")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.ink900.opacity(0.6))
                                        .kerning(0.5)
                                    
                                    HeroInsightCard(insight: hero, isPremium: viewModel.isPremium, onActionTapped: { action in
                                        print("Tapped \(action.title)")
                                    }, onCardTapped: {
                                        print("Tapped Hero Card")
                                    })
                                }
                            }
                            
                            // Other Patterns
                            if !viewModel.patternCards.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("─── OTHER PATTERNS ───")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.ink900.opacity(0.6))
                                        .kerning(0.5)
                                    
                                    ForEach(viewModel.patternCards) { insight in
                                        PatternCard(insight: insight, isPremium: viewModel.isPremium, onCardTapped: {
                                            print("Tapped Pattern Card")
                                        })
                                    }
                                }
                            }
                            
                            // Benchmark
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
                            
                            // Ask Coach
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
                    .padding(20)
                    .padding(.bottom, 60)
                }
                .refreshable {
                    await viewModel.refreshInsights()
                }
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
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
}
