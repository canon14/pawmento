import SwiftUI

struct HeroInsightCard: View {
    let insight: Insight
    let isPremium: Bool
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
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(insight.tier.accentColor)
                        Text(insight.tier.label)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(Color.sage)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    if insight.isPremiumGated {
                        Text("Premium")
                            .font(.system(size: 8, weight: .bold))
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
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.ink900)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.narrative)
                        .font(.system(size: 15, weight: .regular))
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
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.ink900.opacity(0.5))
                    
                    HStack(spacing: 12) {
                        if insight.actions.count > 0 {
                            let primary = insight.actions[0]
                            Button(action: { onActionTapped?(primary) }) {
                                Text(primary.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(isLocked ? Color.sage.opacity(0.3) : Color.sage)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(isLocked)
                        }
                        
                        if insight.actions.count > 1 {
                            let secondary = insight.actions[1]
                            Button(action: { onActionTapped?(secondary) }) {
                                Text(secondary.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.white)
                                    .foregroundColor(.ink900)
                                    .cornerRadius(12)
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
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.sage.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: Color(red: 44/255, green: 95/255, blue: 93/255).opacity(0.08), radius: 12, x: 0, y: 2)
            .overlay(
                // Paywall overlay for free users
                Group {
                    if isLocked {
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.ink900)
                            Text("Unlock this insight for Buddy")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.ink900)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
