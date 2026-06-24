import SwiftUI

struct InsightDetailScreen: View {
    let insight: Insight
    var onActionTapped: ((InsightAction) -> Void)? = nil
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Tier Pill
                HStack(spacing: 5) {
                    Image(systemName: insight.tier.iconName)
                        .font(.system(size: 10))
                    Text(insight.tier.rawValue.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(pillColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(pillColor.opacity(0.15))
                .clipShape(Capsule())
                
                // Headline
                Text(insight.headline)
                    .font(.displaySM)
                    .foregroundColor(.primaryText)
                
                // Unblurred Chart
                InlineChartView(data: insight.visualization)
                    .frame(height: 160)
                    .padding(.vertical, 16)
                
                // Narrative
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader("AI Analysis")
                    
                    Text(insight.narrative)
                        .font(.bodyMD)
                        .foregroundColor(.primaryText)
                        .lineSpacing(6)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Evidence
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("Based on \(insight.evidenceCount) logged events")
                        .font(.bodyMD)
                        .foregroundColor(.secondaryText)
                    Spacer()
                }
                .padding(14)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(AppRadius.input)
                
                // Actions
                VStack(spacing: 10) {
                    ForEach(insight.actions) { action in
                        Button(action: {
                            onActionTapped?(action)
                        }) {
                            Text(action.title)
                                .font(.headlineSM)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .foregroundColor(action.isPrimary ? .white : .primaryText)
                                .background(
                                    Group {
                                        if action.isPrimary {
                                            LinearGradient(
                                                colors: [Color.primary, Color.primary.opacity(0.85)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        } else {
                                            Color.surfaceContainerLowest
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.md)
                                        .stroke(
                                            action.isPrimary ? Color.clear : Color.primary.opacity(0.12),
                                            lineWidth: action.isPrimary ? 0 : 1
                                        )
                                )
                                .shadow(
                                    color: action.isPrimary ? Color.primary.opacity(0.2) : Color.clear,
                                    radius: 4, x: 0, y: 2
                                )
                        }
                    }
                }
                .padding(.top, 16)
            }
            .padding(24)
        }
        .background(Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Insight Details")
                    .font(.headlineSM)
                    .foregroundColor(.primaryText)
            }
        }
    }
    
    private var pillColor: Color {
        switch insight.tier {
        case .strong: return Color.primary
        case .moderate: return Color.warning
        case .positive: return Color.primary
        case .emerging: return Color.ink600
        }
    }
}
