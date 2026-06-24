import SwiftUI

struct HeroInsightCard: View {
    let insight: Insight
    let isPremium: Bool
    let petName: String
    var onActionTapped: ((InsightAction) -> Void)?
    var onCardTapped: (() -> Void)?
    
    private var isLocked: Bool {
        insight.isPremiumGated && !isPremium
    }
    
    var body: some View {
        Button {
            onCardTapped?()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header Row
                HStack(alignment: .top) {
                    // Confidence Pill
                    HStack(spacing: 5) {
                        Image(systemName: insight.tier.iconName)
                            .font(.system(size: 10))
                        Text(insight.tier.label)
                            .font(.labelSM)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    if insight.isPremiumGated {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text("Premium")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ink900.opacity(0.9))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding([.top, .horizontal], 20)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.headline)
                        .font(.headlineMD)
                        .foregroundColor(.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.narrative)
                        .font(.bodyMD)
                        .foregroundColor(.secondaryText)
                        .lineSpacing(4)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 14)
                .padding(.horizontal, 20)
                .blur(radius: isLocked ? 4 : 0)
                
                // Chart
                InlineChartView(data: insight.visualization)
                    .frame(height: 80)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .blur(radius: isLocked ? 6 : 0)
                
                // Footer
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                        Text("Based on \(insight.evidenceCount) logged events · Confidence: \(Int(insight.confidence * 100))%")
                            .font(.labelSM)
                            .foregroundColor(.tertiaryText)
                    }
                    
                    HStack(spacing: 10) {
                        if insight.actions.count > 0 {
                            let primary = insight.actions[0]
                            Button(action: { onActionTapped?(primary) }) {
                                Text(primary.title)
                                    .font(.labelSemibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(
                                        LinearGradient(
                                            colors: isLocked
                                                ? [Color.primary.opacity(0.3), Color.primary.opacity(0.2)]
                                                : [Color.primary, Color.primary.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.input))
                                    .shadow(
                                        color: isLocked ? Color.clear : Color.primary.opacity(0.2),
                                        radius: 4, x: 0, y: 2
                                    )
                            }
                            .disabled(isLocked)
                        }
                        
                        if insight.actions.count > 1 {
                            let secondary = insight.actions[1]
                            Button(action: { onActionTapped?(secondary) }) {
                                Text(secondary.title)
                                    .font(.labelSemibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(Color.surfaceContainerLowest)
                                    .foregroundColor(.primaryText)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.input))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.input)
                                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(20)
                .blur(radius: isLocked ? 4 : 0)
            }
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(Color.primary.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: Color.primary.opacity(0.08), radius: 16, x: 0, y: 6)
            .overlay(
                // Paywall overlay for free users
                Group {
                    if isLocked {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.primary)
                            }
                            Text("Unlock this insight for \(petName)")
                                .font(.labelSemibold)
                                .foregroundColor(.primaryText)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            )
        }
        .buttonStyle(SquishyCardStyle())
    }
}
