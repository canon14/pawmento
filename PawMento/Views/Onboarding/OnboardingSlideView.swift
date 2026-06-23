import SwiftUI

struct OnboardingSlideView<Illustration: View>: View {
    let illustration: Illustration
    let headline: String
    let bodyText: String
    let slideIndex: Int
    let currentIndex: Int
    
    @State private var illustrationVisible = false
    @State private var headlineVisible = false
    @State private var bodyVisible = false
    
    private var isActive: Bool {
        slideIndex == currentIndex
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            // Illustration Area
            illustration
                .frame(width: 280, height: 280)
                .opacity(illustrationVisible ? 1 : 0)
                .scaleEffect(illustrationVisible ? 1 : 0.92)
            
            // Spacer below illustration
            Spacer()
                .frame(height: 36)
            
            // Headline
            Text(headline)
                .font(.displaySM)
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(headlineVisible ? 1 : 0)
                .offset(y: headlineVisible ? 0 : 12)
            
            // Spacer below headline
            Spacer()
                .frame(height: 12)
            
            // Body Text
            Text(bodyText)
                .font(.bodyMD)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .lineLimit(3)
                .padding(.leading, 40)
                .padding(.trailing, 48)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(bodyVisible ? 1 : 0)
                .offset(y: bodyVisible ? 0 : 10)
            
            // Push everything up
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
        .onChange(of: currentIndex) { _, newIndex in
            if newIndex == slideIndex {
                animateIn()
            } else {
                // Reset when leaving this slide
                illustrationVisible = false
                headlineVisible = false
                bodyVisible = false
            }
        }
        .onAppear {
            if isActive {
                animateIn()
            }
        }
    }
    
    private func animateIn() {
        // Staggered entrance: illustration → headline → body
        withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
            illustrationVisible = true
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.2)) {
            headlineVisible = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            bodyVisible = true
        }
    }
}
