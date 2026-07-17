import SwiftUI

/// Reusable rounded skeleton placeholder with the shared shimmer animation.
struct SkeletonBlock: View {
    var cornerRadius: CGFloat = AppRadius.card
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.surfaceContainerHigh.opacity(0.85))
            .shimmer()
    }
}

#Preview {
    VStack(spacing: 16) {
        SkeletonBlock()
            .frame(height: 120)
        SkeletonBlock(cornerRadius: AppRadius.sm)
            .frame(height: 40)
    }
    .padding()
    .background(Color.background)
}
