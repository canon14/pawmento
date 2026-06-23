import SwiftUI

// MARK: - Slide 1: "Notice the little things"
struct Slide1Illustration: View {
    @State private var animate = false
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [Color.warmTanTintBg, Color.warmTanTintBg.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
            
            // Decorative rings
            Circle()
                .stroke(Color.warmTanHue.opacity(0.1), lineWidth: 1)
                .frame(width: 220, height: 220)
                .scaleEffect(animate ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animate)
            
            Circle()
                .stroke(Color.warmTanHue.opacity(0.06), lineWidth: 1)
                .frame(width: 260, height: 260)
                .scaleEffect(animate ? 0.97 : 1.03)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(0.5), value: animate)
            
            // Central illustration — magnifying glass over paw
            ZStack {
                // Paw print (subject being observed)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.warmTanDarkHue, Color.warmTanHue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: 10)
                
                // Magnifying glass overlay
                Circle()
                    .stroke(Color.sageHue, lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .fill(Color.sageHue.opacity(0.08))
                    )
                    .offset(x: 15, y: -5)
                
                // Handle of magnifying glass
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.sageHue)
                    .frame(width: 6, height: 30)
                    .rotationEffect(.degrees(45))
                    .offset(x: 50, y: 30)
            }
            
            // Floating insight chips
            InsightChip(text: "scratching ↑", color: .warmTanHue)
                .offset(x: -80, y: -70)
                .opacity(animate ? 1.0 : 0.3)
                .offset(y: animate ? -3 : 3)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animate)
            
            InsightChip(text: "appetite ↓", color: .sageHue)
                .offset(x: 75, y: -80)
                .opacity(animate ? 0.9 : 0.4)
                .offset(y: animate ? 2 : -2)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.8), value: animate)
            
            InsightChip(text: "energy ✓", color: .primary)
                .offset(x: 80, y: 70)
                .opacity(animate ? 0.85 : 0.35)
                .offset(y: animate ? -2 : 2)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.4), value: animate)
            
            // Pulse indicator dot
            Circle()
                .fill(Color.coral500)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.coral500.opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulse ? 2.0 : 1.0)
                        .opacity(pulse ? 0.0 : 0.6)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
                )
                .offset(x: -65, y: 50)
        }
        .onAppear {
            animate = true
            pulse = true
        }
    }
}

// MARK: - Slide 2: "Log anything in under 10 seconds"
struct Slide2Illustration: View {
    @State private var animate = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var arcProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [Color.sageTintBg, Color.sageTintBg.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
            
            // Decorative dots grid (subtle)
            ForEach(0..<4, id: \.self) { row in
                ForEach(0..<4, id: \.self) { col in
                    Circle()
                        .fill(Color.sageHue.opacity(0.1))
                        .frame(width: 4, height: 4)
                        .offset(
                            x: CGFloat(col - 2) * 30 - 70,
                            y: CGFloat(row - 2) * 30 + 70
                        )
                }
            }
            
            // Phone mockup
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfaceContainerLowest)
                .frame(width: 110, height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.ink300, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            
            // Phone screen content — mini log entry
            VStack(spacing: 6) {
                // Category emoji row
                HStack(spacing: 6) {
                    MiniCategoryChip(emoji: "🥩", isSelected: false)
                    MiniCategoryChip(emoji: "💧", isSelected: true)
                    MiniCategoryChip(emoji: "🦮", isSelected: false)
                }
                
                // Mini note line
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.ink200)
                    .frame(width: 70, height: 6)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.ink200.opacity(0.5))
                    .frame(width: 50, height: 6)
                
                Spacer().frame(height: 4)
                
                // Save button
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary)
                    .frame(width: 70, height: 22)
                    .overlay(
                        Text("Save")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 90, height: 100)
            .offset(y: -10)
            
            // Animated arc path (swipe gesture)
            Circle()
                .trim(from: 0, to: arcProgress)
                .stroke(Color.sageHue.opacity(0.5), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 4]))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-120))
            
            // Camera icon (source)
            ZStack {
                Circle()
                    .fill(Color.surfaceContainerLowest)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryText)
            }
            .offset(x: -80, y: 20)
            
            // Checkmark (destination) — animated entrance
            ZStack {
                Circle()
                    .fill(Color.sageHue.opacity(0.15))
                    .frame(width: 46, height: 46)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.sageHue, Color.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .scaleEffect(checkmarkScale)
            .offset(x: 80, y: 20)
            
            // Timer badge
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8))
                Text("10s")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.warmTanDarkHue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.warmTanTintBg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.warmTanHue.opacity(0.3), lineWidth: 1))
            .offset(x: 80, y: -70)
            .opacity(animate ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                arcProgress = 0.35
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.0)) {
                checkmarkScale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.5).delay(0.8)) {
                animate = true
            }
        }
    }
}

// MARK: - Slide 3: "Patterns your vet will want to see"
struct Slide3Illustration: View {
    @State private var animate = false
    @State private var barHeights: [CGFloat] = [0, 0, 0, 0, 0, 0, 0]
    
    private let targetHeights: [CGFloat] = [40, 60, 30, 90, 50, 70, 40]
    private let barColors: [Color] = [
        Color.warmTanHue.opacity(0.5),
        Color.warmTanHue.opacity(0.65),
        Color.warmTanHue.opacity(0.4),
        Color.warmTanHue,
        Color.warmTanHue.opacity(0.55),
        Color.warmTanHue.opacity(0.75),
        Color.warmTanHue.opacity(0.45)
    ]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [Color.warmCreamTintBg, Color.warmCreamTintBg.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
            
            // Chart area
            VStack(spacing: 0) {
                Spacer()
                
                // Trend line overlay
                Path { path in
                    let points: [CGPoint] = [
                        CGPoint(x: 20, y: 100 - barHeights[0]),
                        CGPoint(x: 40, y: 100 - barHeights[1]),
                        CGPoint(x: 60, y: 100 - barHeights[2]),
                        CGPoint(x: 80, y: 100 - barHeights[3]),
                        CGPoint(x: 100, y: 100 - barHeights[4]),
                        CGPoint(x: 120, y: 100 - barHeights[5]),
                        CGPoint(x: 140, y: 100 - barHeights[6])
                    ]
                    path.move(to: points[0])
                    for i in 1..<points.count {
                        let control = CGPoint(
                            x: (points[i-1].x + points[i].x) / 2,
                            y: (points[i-1].y + points[i].y) / 2
                        )
                        path.addQuadCurve(to: points[i], control: control)
                    }
                }
                .stroke(Color.coral500.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 160, height: 100)
                .offset(x: 0, y: 35)
                
                // Animated bar chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColors[i])
                            .frame(width: 14, height: barHeights[i])
                    }
                }
            }
            .frame(height: 140)
            .offset(y: 40)
            
            // Insight Card (floating)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.coral500)
                    Text("Pattern detected")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primaryText)
                }
                
                Text("Scratching increases after chicken meals")
                    .font(.system(size: 9))
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 8))
                    Text("14 day pattern")
                        .font(.system(size: 8, weight: .medium))
                }
                .foregroundColor(.sageHue)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.sageTintBg)
                .cornerRadius(4)
            }
            .padding(12)
            .frame(width: 180)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.input)
                    .fill(Color.surfaceContainerLowest)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.input)
                    .stroke(Color.warmTanHue.opacity(0.2), lineWidth: 1)
            )
            .offset(y: -50)
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 10)
        }
        .onAppear {
            for i in 0..<7 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.08)) {
                    barHeights[i] = targetHeights[i]
                }
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
                animate = true
            }
        }
    }
}

// MARK: - Slide 4: "Your pet deserves this kind of care"
struct Slide4Illustration: View {
    @State private var animate = false
    @State private var heartScale: CGFloat = 0
    @State private var ringProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [Color.errorTintBg, Color.warmCreamTintBg.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
            
            // Wellness ring (like Apple Watch)
            ZStack {
                // Track
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primary, Color.sageHue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                // Score
                VStack(spacing: 2) {
                    Text("92")
                        .font(.custom("PlusJakartaSans-Bold", size: 36))
                        .foregroundColor(.primaryText)
                    Text("wellness")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondaryText)
                }
            }
            .offset(y: -10)
            
            // Floating paw prints (journey metaphor)
            Image(systemName: "pawprint.fill")
                .font(.system(size: 16))
                .foregroundColor(Color.warmTanHue.opacity(0.2))
                .offset(x: -90, y: -80)
                .rotationEffect(.degrees(-20))
                .opacity(animate ? 1 : 0)
            
            Image(systemName: "pawprint.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.warmTanHue.opacity(0.35))
                .offset(x: -60, y: -50)
                .rotationEffect(.degrees(-10))
                .opacity(animate ? 1 : 0)
            
            Image(systemName: "pawprint.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.warmTanHue.opacity(0.5))
                .offset(x: -25, y: -25)
                .opacity(animate ? 1 : 0)
            
            // Heart accent
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(colors: [Color.coral500, Color.coral500.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
                .scaleEffect(heartScale)
                .offset(x: 75, y: -60)
            
            // Stats chips
            HStack(spacing: 8) {
                StatChip(icon: "figure.walk", value: "3 walks", color: .sageHue)
                StatChip(icon: "fork.knife", value: "fed ✓", color: .warmTanHue)
            }
            .offset(y: 80)
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                ringProgress = 0.92
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.8)) {
                heartScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                animate = true
            }
        }
    }
}

// MARK: - Reusable Illustration Components

struct InsightChip: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(color.opacity(0.2), lineWidth: 0.5)
            )
    }
}

struct MiniCategoryChip: View {
    let emoji: String
    let isSelected: Bool
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 14))
            .frame(width: 26, height: 26)
            .background(isSelected ? Color.primaryContainer : Color.surfaceContainerHigh)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }
}

struct StatChip: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(value)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.surfaceContainerLowest)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        Slide1Illustration()
        Slide2Illustration()
    }
}
