import SwiftUI

struct CelebrationOverlay: View {
    var message: String = "First log! You're on your way."
    var onDismiss: () -> Void = {}
    
    @State private var appeared = false
    @State private var confettiPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.35 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            VStack(spacing: 16) {
                ZStack {
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(confettiColor(for: index))
                            .frame(width: 8, height: 8)
                            .offset(confettiOffset(for: index))
                            .opacity(appeared ? 1 : 0)
                    }
                    
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.primary)
                        .scaleEffect(appeared ? 1 : 0.4)
                }
                .frame(height: 72)
                
                Text(message)
                    .font(.headlineMD)
                    .foregroundColor(.onSurface)
                    .multilineTextAlignment(.center)
                
                Text("Tap to continue")
                    .font(.labelSM)
                    .foregroundColor(.onSurfaceVariant)
            }
            .padding(28)
            .frame(maxWidth: 300)
            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .warmShadow()
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
                confettiPhase = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismiss()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { dismiss() }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
    
    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [.primary, .warning, .error, .primaryContainer]
        return colors[index % colors.count]
    }
    
    private func confettiOffset(for index: Int) -> CGSize {
        let angle = Double(index) / 8.0 * .pi * 2
        let radius = Double(appeared ? 36 : 0)
        let scale = 0.8 + Double(confettiPhase) * 0.2
        return CGSize(
            width: Darwin.cos(angle) * radius * scale,
            height: Darwin.sin(angle) * radius * scale
        )
    }
}

#Preview {
    CelebrationOverlay()
}
