import SwiftUI

struct PatternAlertCard: View {
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @StateObject private var insightsVM = InsightsViewModel()
    var setupProgress: SetupProgress?
    var action: (() -> Void)?
    var onInsightsLoaded: ((Bool) -> Void)? = nil
    var onStrongInsightDetected: ((Insight) -> Void)? = nil
    
    @State private var isFirstInsightMilestone = false
    @State private var showShareSheet = false
    @State private var shareInsight: Insight?
    @State private var lastLoadedLogCount: Int?
    
    private var allInsights: [Insight] {
        var insights: [Insight] = []
        if let hero = insightsVM.heroInsight {
            insights.append(hero)
        }
        insights.append(contentsOf: insightsVM.patternCards)
        return insights
    }
    
    private var topInsight: Insight? {
        InsightOrdering.bestInsight(from: allInsights)
    }
    
    private var hasAlert: Bool { topInsight != nil }
    
    private var hasFirstInsight: Bool {
        insightsVM.heroInsight != nil || !insightsVM.patternCards.isEmpty
    }
    
    private var shouldShowLadderTeaser: Bool {
        guard let setupProgress else { return false }
        return !setupProgress.hasFirstInsight && !hasAlert
    }
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "your pet"
        let accentColor: Color = isFirstInsightMilestone ? .primary : (hasAlert ? .warning : .primary)
        
        Group {
            if insightsVM.isAnalyzing {
                Color.clear
                    .frame(height: 170)
            } else if hasAlert, let insight = topInsight {
                if isFirstInsightMilestone {
                    milestoneCard(insight: insight, petName: petName, accentColor: accentColor)
                } else {
                    alertCard(insight: insight, petName: petName, accentColor: accentColor)
                }
            } else if shouldShowLadderTeaser, let setup = setupProgress {
                comingSoonCard(setup: setup, accentColor: .primary)
            } else {
                allClearCard(petName: petName, accentColor: .primary)
            }
        }
        .task(id: "\(petStore.activePet?.id.uuidString ?? "none")-\(logStore.logs.count)") {
            await loadInsightsIfNeeded()
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
    
    // MARK: - First-insight milestone card
    
    private func milestoneCard(insight: Insight, petName: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                
                Text("Your first pattern!")
                    .font(.headlineSM)
                    .foregroundColor(accentColor)
            }
            
            Text(insight.headline)
                .font(.bodyMD)
                .foregroundColor(accentColor)
                .lineLimit(1)
            
            Text(insight.narrative)
                .font(.bodySM)
                .foregroundColor(accentColor.opacity(0.75))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
            
            HStack(spacing: 8) {
                Button(action: { presentShare(for: insight) }) {
                    HStack(spacing: 4) {
                        Text("Share with vet")
                            .font(.labelSM)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Button(action: { action?() }) {
                    HStack(spacing: 4) {
                        Text("See analysis")
                            .font(.labelSM)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(accentColor.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 170)
        .background(
            Color.primaryContainer.opacity(0.25)
                .overlay(.ultraThinMaterial.opacity(0.7))
        )
        .cornerRadius(AppRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(accentColor.opacity(0.15), lineWidth: 1)
        )
        .warmShadow()
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your first pattern. \(insight.headline). \(insight.narrative)")
    }
    
    // MARK: - Alert Card (real insight found)
    
    private func alertCard(insight: Insight, petName: String, accentColor: Color) -> some View {
        Button(action: { action?() }) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.4), accentColor.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)
                    .offset(x: 30, y: -30)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        
                        Text(insight.headline)
                            .font(.headlineSM)
                            .foregroundColor(accentColor)
                            .lineLimit(1)
                    }
                    
                    Text(insight.narrative)
                        .font(.bodySM)
                        .foregroundColor(accentColor.opacity(0.75))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                    
                    HStack(spacing: 4) {
                        Text("See analysis")
                            .font(.labelSM)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 1))
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 170)
            .background(
                Color.warningBackground
                    .overlay(.ultraThinMaterial.opacity(0.7))
            )
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .warmShadow()
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Pattern noticed. \(insight.headline). \(insight.narrative)")
        }
        .buttonStyle(SquishyCardStyle())
    }
    
    // MARK: - Coming Soon Card (setup ladder proximity)
    
    private func comingSoonCard(setup: SetupProgress, accentColor: Color) -> some View {
        let dayLabel = setup.hasFirstLog ? max(setup.distinctDaysLogged, 1) : 0
        let bodyCopy: String
        if !setup.hasFirstLog {
            bodyCopy = "Start logging to unlock your first pattern for \(setup.petName)."
        } else {
            bodyCopy = "Your first pattern unlocks after ~3 days of logging — you're on day \(dayLabel)."
        }
        
        return Button(action: { action?() }) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.35), accentColor.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)
                    .offset(x: 30, y: -30)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        
                        Text("Patterns coming soon")
                            .font(.headlineSM)
                            .foregroundColor(accentColor)
                    }
                    
                    Text(bodyCopy)
                        .font(.bodySM)
                        .foregroundColor(accentColor.opacity(0.75))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                    
                    HStack(spacing: 4) {
                        Text("View Insights")
                            .font(.labelSM)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 1))
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 170)
            .background(
                Color.primaryContainer.opacity(0.25)
                    .overlay(.ultraThinMaterial.opacity(0.7))
            )
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .warmShadow()
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Patterns coming soon. \(bodyCopy)")
        }
        .buttonStyle(SquishyCardStyle())
    }
    
    // MARK: - All Clear Card (mature user, no patterns)
    
    private func allClearCard(petName: String, accentColor: Color) -> some View {
        Button(action: { action?() }) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.4), accentColor.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)
                    .offset(x: 30, y: -30)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        
                        Text("All Clear")
                            .font(.headlineSM)
                            .foregroundColor(accentColor)
                    }
                    
                    Text("No anomalies for \(petName).")
                        .font(.bodySM)
                        .foregroundColor(accentColor.opacity(0.75))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                    
                    HStack(spacing: 4) {
                        Text("View Insights")
                            .font(.labelSM)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 1))
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 170)
            .background(
                Color.primaryContainer.opacity(0.25)
                    .overlay(.ultraThinMaterial.opacity(0.7))
            )
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .warmShadow()
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("All Clear. No anomalies detected for \(petName).")
        }
        .buttonStyle(SquishyCardStyle())
    }
    
    // MARK: - Data Loading
    
    private func loadInsightsIfNeeded() async {
        guard let pet = petStore.activePet else { return }
        let logCount = logStore.logs.count
        let forceRefresh = lastLoadedLogCount != nil && lastLoadedLogCount != logCount
        let wasFirstInsight = setupProgress?.hasFirstInsight ?? false
        await insightsVM.loadInsights(for: pet, forceRefresh: forceRefresh)
        lastLoadedLogCount = logCount
        isFirstInsightMilestone = !wasFirstInsight && hasFirstInsight
        onInsightsLoaded?(hasFirstInsight)
        if let strong = PaywallEventGate.strongInsight(in: allInsights) {
            onStrongInsightDetected?(strong)
        }
    }
    
    private func presentShare(for insight: Insight) {
        shareInsight = insight
        showShareSheet = true
    }
}

#Preview("Ladder teaser") {
    let setup = SetupProgress(
        hasPet: true,
        hasFirstLog: true,
        hasThreeDaysLogged: false,
        hasFirstInsight: false,
        distinctDaysLogged: 1,
        petName: "Luna"
    )
    return PatternAlertCard(setupProgress: setup)
        .environmentObject(PetStore())
        .environmentObject(LogStore())
        .frame(width: 260)
        .padding()
        .background(Color.background)
}

#Preview("All clear") {
    PatternAlertCard(setupProgress: nil)
        .environmentObject(PetStore())
        .environmentObject(LogStore())
        .frame(width: 260)
        .padding()
        .background(Color.background)
}
