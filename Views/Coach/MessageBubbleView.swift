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
                        gradient: Gradient(colors: [Color.warmTan, Color.warmTan.opacity(0.9)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(BubbleShape(isUser: true))
            
            // Timestamp
            Text(message.timestamp, style: .time)
                .font(.labelSM)
                .foregroundColor(.tertiaryText)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.78, alignment: .trailing)
    }
    
    var coachBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            // Coach Avatar
            Text("🐶")
                .font(.system(size: 18))
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                if message.isEmergency {
                    Text("This sounds urgent")
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
            .background(message.isEmergency ? Color.warmCoralTintBg : Color.surfaceBright)
            .clipShape(BubbleShape(isUser: false))
            .overlay(
                BubbleShape(isUser: false)
                    .stroke(message.isEmergency ? Color.warmCoral : Color.outline.opacity(0.08), lineWidth: message.isEmergency ? 3 : 1)
            )
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.78, alignment: .leading)
    }
}
