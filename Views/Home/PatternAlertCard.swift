import SwiftUI

struct PatternAlertCard: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background blur effect from design
            Circle()
                .fill(Color.warningBorder.opacity(0.3))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .offset(x: 40, y: -40)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.warning)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Text("Pattern noticed")
                        .font(.headlineSM)
                        .foregroundColor(Color.warning)
                }
                
                Text("Buddy's scratched 3 times this week.")
                    .font(.bodyMD)
                    .foregroundColor(Color.warning.opacity(0.8))
                
                HStack {
                    Spacer()
                    Button(action: {
                        // See full analysis action
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                            Text("See full analysis")
                                .font(.labelMD)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Color.warning)
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Color.warningBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.warningBorder, lineWidth: 1)
        )
        .warmShadow()
        .clipped()
    }
}

#Preview {
    PatternAlertCard()
        .padding()
        .background(Color.background)
}
