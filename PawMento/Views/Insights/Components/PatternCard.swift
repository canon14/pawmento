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
            return ("MODERATE", Color.orange.opacity(0.2), Color.orange)
        case .positive:
            return ("POSITIVE", Color.primary.opacity(0.2), Color.primary)
        case .emerging:
            return ("EMERGING", Color.ink900.opacity(0.1), Color.ink900.opacity(0.8))
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
                            .font(.caption)
                            .foregroundColor(pillConfig.fg)
                        Text(pillConfig.text)
                            .font(.caption)
                            .foregroundColor(pillConfig.fg)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(pillConfig.bg)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    if insight.isPremiumGated {
                        Text("Premium")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .frame(height: 14)
                            .background(Color.ink900)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding([.top, .horizontal], 16)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.headline)
                        .font(.bodyMD)
                        .foregroundColor(.ink900)
                        .lineLimit(1)
                        .blur(radius: isLocked ? 2 : 0)
                    
                    Text(insight.narrative)
                        .font(.bodySM)
                        .foregroundColor(.ink900.opacity(0.8))
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
            .background(Color.surface0)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.ink900.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                Group {
                    if isLocked {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.headlineMD)
                                .foregroundColor(.ink900)
                            Text("Unlock insight")
                                .font(.bodySM)
                                .foregroundColor(.ink900)
                        }
                        .padding(12)
                        .background(Color.surface0.opacity(0.8))
                        .cornerRadius(AppRadius.input)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
