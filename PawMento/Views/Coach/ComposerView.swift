import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    @Binding var freeQuestionsRemaining: Int
    let petName: String
    let onCameraTap: () -> Void
    let onSend: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                // Attachments
                Button(action: onCameraTap) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Text Field
                TextField(placeholderText(), text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.bodyMD)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.surfaceContainerLowest)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.primary.opacity(text.isEmpty ? 0 : 0.2), lineWidth: 1)
                    )
                
                // Send Button
                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.bodyMD.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                        .opacity(text.isEmpty ? 0.3 : 1.0)
                        .scaleEffect(text.isEmpty ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: text.isEmpty)
                }
                .disabled(text.isEmpty)
            }
            
            // Counter Pill
            Text(counterText())
                .font(.labelSM)
                .foregroundColor(counterColor())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.surfaceContainerLowest)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(counterColor().opacity(0.3), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            Color.surfaceContainerLowest.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
        if freeQuestionsRemaining > 2 { return .secondaryText }
        if freeQuestionsRemaining == 2 { return .warning }
        return .error
    }
}
