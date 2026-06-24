import SwiftUI

struct InsightEmptyStateView: View {
    let state: InsightsViewModel.ViewState
    let petName: String
    let onAction: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    .frame(width: 100, height: 100)
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1.0 : 0)
                
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 72, height: 72)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.primary)
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .opacity(appeared ? 1.0 : 0)
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.6), value: appeared)
            .padding(.bottom, 4)
            
            Text(title)
                .font(.headlineMD)
                .foregroundColor(.primaryText)
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)
            
            Text(message)
                .font(.bodyMD)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 6)
                .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)
            
            Button(action: onAction) {
                Text(buttonTitle)
                    .font(.labelSemibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.primary, Color.primary.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.primary.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 8)
            .opacity(appeared ? 1.0 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
        .onAppear {
            appeared = true
        }
    }
    
    private var iconName: String {
        switch state {
        case .noData: return "doc.text.magnifyingglass"
        case .noDataForRange: return "calendar.badge.exclamationmark"
        case .noPatterns: return "sparkles"
        case .offline: return "wifi.slash"
        case .error: return "exclamationmark.triangle"
        default: return "sparkles"
        }
    }
    
    private var title: String {
        switch state {
        case .noData: return "Let's gather some data"
        case .noDataForRange: return "Quiet week"
        case .noPatterns: return "Looking good!"
        case .offline: return "You're offline"
        case .error: return "Something went wrong"
        default: return ""
        }
    }
    
    private var message: String {
        switch state {
        case .noData: return "The AI Coach needs a few more logs to start analyzing patterns for \(petName)."
        case .noDataForRange: return "No activity was logged during this time period."
        case .noPatterns: return "We analyzed the data and didn't find any concerning health correlations."
        case .offline: return "The Insight Engine requires an internet connection to run the LLM analysis."
        case .error(let msg): return "We couldn't analyze the data right now. \(msg)"
        default: return ""
        }
    }
    
    private var buttonTitle: String {
        switch state {
        case .noData: return "Add a Log"
        case .noDataForRange: return "View All Time"
        case .noPatterns: return "Ask Coach a Question"
        case .offline, .error: return "Try Again"
        default: return ""
        }
    }
}
