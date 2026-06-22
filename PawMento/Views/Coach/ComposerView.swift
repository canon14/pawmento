import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    @Binding var freeQuestionsRemaining: Int
    let petName: String
    let onCameraTap: () -> Void
    let onSend: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(alignment: .bottom, spacing: 12) {
                // Attachments
                Button(action: onCameraTap) {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                        .foregroundColor(.tertiaryText)
                }
                .frame(width: 32, height: 40)
                
                // Text Field
                TextField(placeholderText(), text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.bodyMD)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#F4F1EC"))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(text.isEmpty ? 0 : 1), lineWidth: 1)
                    )
                
                // Send Button
                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.primary)
                        .clipShape(Circle())
                        .opacity(text.isEmpty ? 0.3 : 1.0)
                }
                .disabled(text.isEmpty)
            }
            
            // Counter
            Text(counterText())
                .font(.labelSM)
                .foregroundColor(counterColor())
                .padding(.trailing, 52) // align under text field
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.outline.opacity(0.12)),
            alignment: .top
        )
    }
    
    private func placeholderText() -> String {
        if freeQuestionsRemaining == 1 {
            return "Last free question — make it count 🐶"
        }
        return "Ask anything about \(petName)..."
    }
    
    private func counterText() -> String {
        if freeQuestionsRemaining > 2 {
            return "\(freeQuestionsRemaining) free this month"
        } else if freeQuestionsRemaining == 1 {
            return "Last free question"
        } else {
            return "\(freeQuestionsRemaining) left"
        }
    }
    
    private func counterColor() -> Color {
        if freeQuestionsRemaining > 2 { return .tertiaryText }
        if freeQuestionsRemaining == 2 { return .warning }
        return .error
    }
}
