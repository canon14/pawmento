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
                        .font(.caption)
                        .foregroundColor(pillColor)
                    Text(insight.tier.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(pillColor)
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(pillColor.opacity(0.2))
                .clipShape(Capsule())
                
                // Headline
                Text(insight.headline)
                    .font(.displaySM)
                    .foregroundColor(.ink900)
                
                // Unblurred Chart
                InlineChartView(data: insight.visualization)
                    .frame(height: 160)
                    .padding(.vertical, 16)
                
                // Narrative
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Analysis")
                        .font(.bodySM)
                        .foregroundColor(.ink900.opacity(0.6))
                    
                    Text(insight.narrative)
                        .font(.bodyMD)
                        .foregroundColor(.ink900)
                        .lineSpacing(6)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Evidence
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.primary)
                    Text("Based on \(insight.evidenceCount) logged events")
                        .font(.bodySM)
                        .foregroundColor(.ink900.opacity(0.8))
                    Spacer()
                }
                .padding(16)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(AppRadius.input)
                
                // Actions
                VStack(spacing: 12) {
                    ForEach(insight.actions) { action in
                        Button(action: {
                            onActionTapped?(action)
                        }) {
                            Text(action.title)
                                .font(.bodyMD)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(action.isPrimary ? Color.primary : Color.surface0)
                                .foregroundColor(action.isPrimary ? .white : .ink900)
                                .cornerRadius(AppRadius.md)
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
                    .font(.bodyMD)
            }
        }
    }
    
    private var pillColor: Color {
        switch insight.tier {
        case .strong: return Color.primary
        case .moderate: return Color.orange
        case .positive: return Color.primary
        case .emerging: return Color.ink900
        }
    }
}
