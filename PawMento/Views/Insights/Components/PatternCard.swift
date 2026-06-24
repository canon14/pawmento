import SwiftUI

struct PatternCard: View {
    let insight: Insight
    let isPremium: Bool
    var onCardTapped: (() -> Void)?
    
    private var isLocked: Bool {
        insight.isPremiumGated && !isPremium
    }
    
    // Tier Pill styling
    private var pillConfig: (text: String, bg: Color, fg: Color) {
        switch insight.tier {
        case .moderate:
            return ("MODERATE", Color.warning.opacity(0.15), Color.warning)
        case .positive:
            return ("POSITIVE", Color.primary.opacity(0.15), Color.primary)
        case .emerging:
            return ("EMERGING", Color.ink900.opacity(0.08), Color.ink600)
        case .strong:
            return ("STRONG", Color.primary, .white)
        }
    }
    
    private var pillIcon: String {
        switch insight.tier {
        case .moderate: return "circle.fill"
        case .positive: return "checkmark.circle.fill"
        case .emerging: return "leaf.fill"
        case .strong: return "bolt.fill"
        }
    }
    
    var body: some View {
        Button(action: {
            onCardTapped?()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Row
                HStack(alignment: .top) {
                    // Tier Pill
                    HStack(spacing: 4) {
                        Image(systemName: pillIcon)
                            .font(.system(size: 9))
                        Text(pillConfig.text)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(pillConfig.fg)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(pillConfig.bg)
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
                .padding([.top, .horizontal], 16)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.headline)
                        .font(.headlineSM)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                        .blur(radius: isLocked ? 2 : 0)
                    
                    Text(insight.narrative)
                        .font(.bodyMD)
                        .foregroundColor(.secondaryText)
                        .lineLimit(2)
                        .blur(radius: isLocked ? 4 : 0)
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
                
                // Chart
                InlineChartView(data: insight.visualization)
                    .frame(height: 60)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .blur(radius: isLocked ? 6 : 0)
            }
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
            .overlay(
                Group {
                    if isLocked {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                            Text("Unlock insight")
                                .font(.labelSM)
                                .foregroundColor(.primaryText)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.input)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            )
        }
        .buttonStyle(SquishyCardStyle())
    }
}
