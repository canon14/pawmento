import SwiftUI

struct InsightEmptyStateView: View {
    let state: InsightsViewModel.ViewState
    let onAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.sage.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 32))
                        .foregroundColor(.sage)
                )
                .padding(.bottom, 8)
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.ink900)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.ink900.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onAction) {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.sage)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.sage.opacity(0.1))
                    .cornerRadius(20)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
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
        case .noData: return "The AI Coach needs a few more logs to start analyzing patterns for Buddy."
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
