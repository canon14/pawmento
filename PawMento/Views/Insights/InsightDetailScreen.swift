import SwiftUI

struct InsightDetailScreen: View {
    let insight: Insight
    var onActionTapped: ((InsightAction) -> Void)? = nil
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Tier Pill
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill") // Simplified for demo
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(pillColor)
                    Text(insight.tier.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(pillColor)
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(pillColor.opacity(0.2))
                .clipShape(Capsule())
                
                // Headline
                Text(insight.headline)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.ink900)
                
                // Unblurred Chart
                InlineChartView(data: insight.visualization)
                    .frame(height: 160)
                    .padding(.vertical, 16)
                
                // Narrative
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Analysis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.ink900.opacity(0.6))
                    
                    Text(insight.narrative)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.ink900)
                        .lineSpacing(6)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Evidence
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.sage)
                    Text("Based on \(insight.evidenceCount) logged events")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.ink900.opacity(0.8))
                    Spacer()
                }
                .padding(16)
                .background(Color.sage.opacity(0.1))
                .cornerRadius(12)
                
                // Actions
                VStack(spacing: 12) {
                    ForEach(insight.actions) { action in
                        Button(action: {
                            onActionTapped?(action)
                        }) {
                            Text(action.title)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(action.isPrimary ? Color.sage : Color.white)
                                .foregroundColor(action.isPrimary ? .white : .ink900)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.ink900.opacity(0.1), lineWidth: action.isPrimary ? 0 : 1)
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
                    .font(.system(size: 16, weight: .semibold))
            }
        }
    }
    
    private var pillColor: Color {
        switch insight.tier {
        case .strong: return Color.sage
        case .moderate: return Color.orange
        case .positive: return Color.sage
        case .emerging: return Color.ink900
        }
    }
}
