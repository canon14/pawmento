import SwiftUI

// Custom shape for asymmetric message bubbles
struct BubbleShape: Shape {
    var isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 18, height: 18)
        )
        return Path(path.cgPath)
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    var showTimestamp: Bool = true
    @State private var isRevealed: Bool = false
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                userBubble
            } else {
                coachBubble
                Spacer()
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.bodyMD)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primary, Color.primary.opacity(0.9)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(BubbleShape(isUser: true))
            
            // Timestamp
            if showTimestamp || isRevealed {
                Text(message.timestamp, style: .time)
                    .font(.labelSM)
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(.leading, 48)
        .textSelection(.enabled)
        .onTapGesture {
            withAnimation { isRevealed.toggle() }
        }
    }
    
    var coachBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            // Coach Avatar
            Text("🧑‍⚕️")
                .font(.headlineSM)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                if message.isEmergency {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("This sounds urgent")
                    }
                    .font(.headlineSM)
                    .foregroundColor(.error)
                }
                
                Text(message.content.isEmpty ? "..." : message.content)
                    .font(.bodyMD)
                    .foregroundColor(.primaryText)
                    .lineSpacing(4) // 1.45 line height equivalent
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(message.isEmergency ? Color.errorTintBg : Color.surfaceBright)
            .clipShape(BubbleShape(isUser: false))
            .overlay(
                BubbleShape(isUser: false)
                    .stroke(message.isEmergency ? Color.error : Color.outline.opacity(0.08), lineWidth: message.isEmergency ? 2 : 1)
            )
        }
        .padding(.trailing, 48)
        .textSelection(.enabled)
        .onTapGesture {
            withAnimation { isRevealed.toggle() }
        }
    }
}
