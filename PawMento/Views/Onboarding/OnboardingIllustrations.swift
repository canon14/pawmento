import SwiftUI

struct Slide1Illustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.warmTanTintBg)
                .frame(width: 280, height: 280)
            
            // Dog symbol
            Image(systemName: "dog.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Color.warmTanDarkHue)
                .offset(y: 20)
            
            // Floating dots
            Circle().fill(Color.sageHue.opacity(0.8)).frame(width: 12, height: 12).offset(x: -60, y: -40)
            Circle().fill(Color.sageHue.opacity(0.5)).frame(width: 8, height: 8).offset(x: 40, y: -60)
            Circle().fill(Color.sageHue.opacity(0.6)).frame(width: 16, height: 16).offset(x: 70, y: 10)
            Circle().fill(Color.sageHue.opacity(0.4)).frame(width: 10, height: 10).offset(x: -80, y: 30)
        }
    }
}

struct Slide2Illustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.sageTintBg)
                .frame(width: 280, height: 280)
            
            // Phone frame
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryText, lineWidth: 3)
                .frame(width: 120, height: 200)
                .background(Color.surface0.cornerRadius(AppRadius.md))
            
            // Arc motion path
            Path { path in
                path.move(to: CGPoint(x: 80, y: 140))
                path.addQuadCurve(to: CGPoint(x: 200, y: 140), control: CGPoint(x: 140, y: 60))
            }
            .stroke(Color.sageHue, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
            
            // Camera
            Image(systemName: "camera.fill")
                .font(.headlineLG)
                .foregroundColor(.primaryText)
                .offset(x: -60, y: 0)
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.displayMD)
                .foregroundColor(Color.warmTanHue)
                .offset(x: 60, y: 0)
            
            // Tag chips
            HStack(spacing: 4) {
                Capsule().fill(Color.sageHue.opacity(0.3)).frame(width: 20, height: 8)
                Capsule().fill(Color.sageHue.opacity(0.3)).frame(width: 30, height: 8)
            }
            .offset(y: 40)
        }
    }
}

struct Slide3Illustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.warmCreamTintBg)
                .frame(width: 280, height: 280)
            
            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.warmTanHue.opacity(0.6)).frame(width: 12, height: 40)
                RoundedRectangle(cornerRadius: 4).fill(Color.warmTanHue.opacity(0.4)).frame(width: 12, height: 60)
                RoundedRectangle(cornerRadius: 4).fill(Color.warmTanHue.opacity(0.8)).frame(width: 12, height: 30)
                RoundedRectangle(cornerRadius: 4).fill(Color.warmTanHue).frame(width: 12, height: 90)
                RoundedRectangle(cornerRadius: 4).fill(Color.warmTanHue.opacity(0.5)).frame(width: 12, height: 50)
                RoundedRectangle(cornerRadius: 4).fill(Color.warmTanHue.opacity(0.7)).frame(width: 12, height: 70)
                RoundedRectangle(cornerRadius: 4).fill(Color.warmTanHue.opacity(0.3)).frame(width: 12, height: 40)
            }
            .offset(y: 40)
            
            // Insight Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                    Text("scratching pattern noticed")
                        .font(.caption)
                }
                .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                    Text("14 days")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondaryContainer)
                .cornerRadius(AppRadius.sm)
            }
            .padding(12)
            .background(Color.surface0)
            .cornerRadius(AppRadius.input)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warmTanHue, lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            .offset(y: -30)
        }
    }
}

struct Slide4Illustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.errorTintBg)
                .frame(width: 280, height: 280)
            
            // Paw prints
            Image(systemName: "pawprint.fill")
                .font(.headlineLG)
                .foregroundColor(Color.warmTanHue.opacity(0.2))
                .offset(x: -80, y: -80)
                .rotationEffect(.degrees(-20))
            
            Image(systemName: "pawprint.fill")
                .font(.headlineLG)
                .foregroundColor(Color.warmTanHue.opacity(0.4))
                .offset(x: -40, y: -40)
                .rotationEffect(.degrees(-10))
            
            Image(systemName: "pawprint.fill")
                .font(.headlineLG)
                .foregroundColor(Color.warmTanHue.opacity(0.6))
                .offset(x: -10, y: -10)
            
            // Empty pet portrait circle
            Circle()
                .fill(Color.warmCream)
                .frame(width: 80, height: 80)
                .overlay(Circle().stroke(Color.warmTanHue, lineWidth: 2))
                .offset(x: 40, y: 40)
        }
    }
}

#Preview {
    VStack {
        Slide1Illustration()
        Slide4Illustration()
    }
}
