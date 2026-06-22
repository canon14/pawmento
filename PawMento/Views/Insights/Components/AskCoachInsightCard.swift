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
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Text("💬")
                    Text("Ask \(petName)'s AI Coach")
                        .font(.labelLG)
                        .foregroundColor(.ink900)
                    Spacer()
                }
                
                // Suggestions
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                        Button(action: {
                            onSuggestionTapped?(suggestion)
                        }) {
                            Text("\"\(suggestion)\"")
                                .font(.bodySM)
                                .foregroundColor(Color.primary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.leading, 28) // Align under text, not icon
                
                // Footer CTA
                HStack {
                    Spacer()
                    Text("Open chat ›")
                        .font(.bodySM)
                        .foregroundColor(Color.primary)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(Color(hex: "E8F1EF")) // Sage 50
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1) // roughly sage-200
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
