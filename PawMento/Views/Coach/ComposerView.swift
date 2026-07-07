import SwiftUI

struct ComposerView: View {
    @Binding var text: String
    @Binding var freeQuestionsRemaining: Int
    let petName: String
    let onCameraTap: () -> Void
    let onSend: () -> Void
    var isSending: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack(alignment: .bottom, spacing: 10) {
                // Camera / Attach
                Button(action: onCameraTap) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .frame(width: 42, height: 42)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                }
                
                // Text Field with focus state
                TextField(placeholderText(), text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.bodyMD)
                    .focused($isFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(
                        isFocused ? Color.surfaceContainerLowest : Color.surfaceContainer.opacity(0.5)
                    )
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                isFocused ? Color.primary.opacity(0.25) : Color.primary.opacity(0.06),
                                lineWidth: isFocused ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: isFocused ? Color.primary.opacity(0.06) : Color.clear,
                        radius: 4, x: 0, y: 2
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                // Send Button
                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            LinearGradient(
                                colors: canSend
                                    ? [Color.primary, Color.primary.opacity(0.85)]
                                    : [Color.primary.opacity(0.3), Color.primary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(
                            color: canSend ? Color.primary.opacity(0.3) : Color.clear,
                            radius: canSend ? 6 : 0,
                            x: 0,
                            y: canSend ? 3 : 0
                        )
                        .scaleEffect(canSend ? 1.0 : 0.95)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canSend)
                }
                .disabled(!canSend)
            }
            
            // Counter with icon
            HStack(spacing: 5) {
                Image(systemName: counterIcon())
                    .font(.system(size: 10))
                Text(counterText())
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(counterColor())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(counterColor().opacity(0.08))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(
            Color.surfaceContainerLowest.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.05)),
            alignment: .top
        )
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
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
    
    private func counterIcon() -> String {
        if freeQuestionsRemaining > 2 { return "sparkle" }
        if freeQuestionsRemaining == 1 { return "exclamationmark.circle" }
        return "exclamationmark.triangle"
    }
    
    private func counterColor() -> Color {
        if freeQuestionsRemaining > 2 { return .secondaryText }
        if freeQuestionsRemaining == 2 { return .warning }
        return .error
    }
}
