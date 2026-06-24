import SwiftUI

struct AskCoachInsightCard: View {
    let suggestions: [String]
    let petName: String
    var onChatTapped: (() -> Void)?
    var onSuggestionTapped: ((String) -> Void)?
    
    var body: some View {
        Button(action: {
            onChatTapped?()
        }) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Text("Ask \(petName)'s AI Coach")
                        .font(.headlineSM)
                        .foregroundColor(.primaryText)
                    Spacer()
                }
                
                // Suggestion pills
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                        Button(action: {
                            onSuggestionTapped?(suggestion)
                        }) {
                            HStack(spacing: 8) {
                                Text("→")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary.opacity(0.5))
                                Text(suggestion)
                                    .font(.bodyMD)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.surfaceContainerLowest.opacity(0.7))
                            .cornerRadius(AppRadius.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.input)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Footer CTA
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Open chat")
                            .font(.labelSM)
                            .foregroundColor(.primary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                }
            }
            .padding(18)
            .background(Color.sage50)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.sage200.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.primary.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(SquishyCardStyle())
    }
}
