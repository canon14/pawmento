import SwiftUI

struct PatternAlertCard: View {
    @EnvironmentObject var petStore: PetStore
    @StateObject private var insightsVM = InsightsViewModel()
    var action: (() -> Void)?
    
    /// The top insight to display (correlation or temporal preferred).
    private var topInsight: Insight? {
        // Prefer correlation/temporal, fall back to any insight
        let preferred = insightsVM.patternCards.first(where: {
            $0.type == .correlation || $0.type == .temporal
        })
        return preferred ?? insightsVM.heroInsight
    }
    
    private var hasAlert: Bool { topInsight != nil }
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "your pet"
        let accentColor: Color = hasAlert ? .warning : .primary
        
        // Hide entirely when still loading or no qualifying insights
        if insightsVM.isAnalyzing || (!hasAlert && insightsVM.viewState != .loading) {
            // Show "All Clear" only when analysis finished with no patterns
            if !insightsVM.isAnalyzing {
                allClearCard(petName: petName, accentColor: .primary)
            }
        } else if hasAlert {
            alertCard(petName: petName, accentColor: accentColor)
        }
    }
    
    // MARK: - Alert Card (real insight found)
    
    private func alertCard(petName: String, accentColor: Color) -> some View {
        let insight = topInsight!
        
        return Button(action: { action?() }) {
            ZStack(alignment: .topTrailing) {
                // Subtle glow accent
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
                    // Icon + Title
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
                    
                    // Description — real narrative from InsightEngine
                    Text(insight.narrative)
                        .font(.bodySM)
                        .foregroundColor(accentColor.opacity(0.75))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                    
                    // CTA
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
        .task(id: petStore.activePet?.id) {
            await loadInsightsIfNeeded()
        }
    }
    
    // MARK: - All Clear Card (no insights)
    
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
        .task(id: petStore.activePet?.id) {
            await loadInsightsIfNeeded()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInsightsIfNeeded() async {
        guard let pet = petStore.activePet else { return }
        await insightsVM.loadInsights(for: pet)
    }
}

#Preview {
    PatternAlertCard()
        .frame(width: 260)
        .padding()
        .background(Color.background)
}
