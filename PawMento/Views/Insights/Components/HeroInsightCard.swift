import SwiftUI

struct HeroInsightCard: View {
    let insight: Insight
    let isPremium: Bool
    let petName: String
    var onActionTapped: ((InsightAction) -> Void)?
    var onCardTapped: (() -> Void)?
    
    // For blurring free users
    private var isLocked: Bool {
        insight.isPremiumGated && !isPremium
    }
    
    var body: some View {
        Button(action: {
            onCardTapped?()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Row
                HStack(alignment: .top) {
                    // Confidence Pill
                    HStack(spacing: 4) {
                        Image(systemName: insight.tier.iconName)
                            .font(.caption)
                            .foregroundColor(insight.tier.accentColor)
                        Text(insight.tier.label)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    if insight.isPremiumGated {
                        Text("Premium")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .frame(height: 14) // Slightly larger than 11pt for touch/render
                            .background(Color.ink900)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding([.top, .horizontal], 20)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.headline)
                        .font(.headlineMD)
                        .foregroundColor(.ink900)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.narrative)
                        .font(.labelLG)
                        .foregroundColor(.ink900.opacity(0.8))
                        .lineSpacing(4) // approx 1.5 line height
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 12)
                .padding(.horizontal, 20)
                .blur(radius: isLocked ? 4 : 0)
                
                // Chart
                InlineChartView(data: insight.visualization)
                    .frame(height: 80)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .blur(radius: isLocked ? 6 : 0)
                
                // Footer
                VStack(alignment: .leading, spacing: 16) {
                    Text("Based on \(insight.evidenceCount) logged events · Confidence: \(Int(insight.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.ink900.opacity(0.5))
                    
                    HStack(spacing: 12) {
                        if insight.actions.count > 0 {
                            let primary = insight.actions[0]
                            Button(action: { onActionTapped?(primary) }) {
                                Text(primary.title)
                                    .font(.bodySM)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(isLocked ? Color.primary.opacity(0.3) : Color.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(AppRadius.input)
                            }
                            .disabled(isLocked)
                        }
                        
                        if insight.actions.count > 1 {
                            let secondary = insight.actions[1]
                            Button(action: { onActionTapped?(secondary) }) {
                                Text(secondary.title)
                                    .font(.bodySM)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.surface0)
                                    .foregroundColor(.ink900)
                                    .cornerRadius(AppRadius.input)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.ink900.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(20)
                .blur(radius: isLocked ? 4 : 0)
            }
            .background(Color.surface0)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: Color(red: 44/255, green: 95/255, blue: 93/255).opacity(0.08), radius: 12, x: 0, y: 2)
            .overlay(
                // Paywall overlay for free users
                Group {
                    if isLocked {
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.headlineLG)
                                .foregroundColor(.ink900)
                            Text("Unlock this insight for \(petName)")
                                .font(.labelLG)
                                .foregroundColor(.ink900)
                        }
                        .padding(16)
                        .background(Color.surface0.opacity(0.8))
                        .cornerRadius(AppRadius.input)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
