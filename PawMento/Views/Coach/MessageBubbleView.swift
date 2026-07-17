import SwiftUI

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
            cornerRadii: CGSize(width: 20, height: 20)
        )
        return Path(path.cgPath)
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    var showTimestamp: Bool = true
    var onRetry: (() -> Void)? = nil
    @State private var isRevealed: Bool = false
    @State private var appeared: Bool = false
    
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
        .opacity(appeared ? 1.0 : 0.0)
        .offset(y: appeared ? 0 : 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
        }
    }
    
    var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.bodyMD)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primary, Color(hex: "#7A6C5D")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(BubbleShape(isUser: true))
                .shadow(color: Color.primary.opacity(0.2), radius: 8, x: 0, y: 4)
            
            if showTimestamp || isRevealed {
                Text(message.timestamp, style: .time)
                    .font(.labelSM)
                    .foregroundColor(.tertiaryText)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.leading, 48)
        .textSelection(.enabled)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { isRevealed.toggle() }
        }
    }
    
    var coachBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Sparkle Avatar with animated gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primary.opacity(0.25), Color.primary.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
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
                    .lineSpacing(6)
                
                // Coach bubble timestamp — tap to reveal or auto-show on 5-min gap
                if showTimestamp || isRevealed {
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(.tertiaryText)
                        .padding(.top, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(message.isEmergency ? Color.errorTintBg : Color.surfaceContainerLowest)
            .clipShape(BubbleShape(isUser: false))
            .overlay(
                BubbleShape(isUser: false)
                    .stroke(
                        message.isEmergency ? Color.error : Color.primary.opacity(0.06),
                        lineWidth: message.isEmergency ? 2 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .padding(.trailing, 48)
        .textSelection(.enabled)
        .onTapGesture {
            if message.isRetryable, let onRetry {
                onRetry()
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { isRevealed.toggle() }
            }
        }
    }
}
