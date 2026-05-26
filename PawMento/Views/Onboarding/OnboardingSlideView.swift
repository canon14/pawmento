import SwiftUI

struct OnboardingSlideView<Illustration: View>: View {
    let illustration: Illustration
    let headline: String
    let bodyText: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Spacer to push illustration down (96pt from safe area top, roughly handled by container)
            Spacer()
                .frame(height: 50) 
            
            // Illustration Area
            illustration
                .frame(width: 280, height: 280)
            
            // Spacer below illustration (40pt)
            Spacer()
                .frame(height: 40)
            
            // Headline
            Text(headline)
                .font(.headlineOnboarding)
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Spacer below headline (12pt)
            Spacer()
                .frame(height: 12)
            
            // Body Text
            Text(bodyText)
                .font(.bodyOnboarding)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.leading)
                .lineSpacing(8) // 1.5 line height approx
                .lineLimit(3)
                .padding(.leading, 40)
                .padding(.trailing, 48)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Push everything up
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
    }
}
