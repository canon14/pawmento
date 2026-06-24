import SwiftUI

struct WellnessScoreHero: View {
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var medicationStore: MedicationStore
    
    var onViewTrendsTapped: (() -> Void)? = nil
    
    @State private var progress: CGFloat = 0.0
    @State private var score: Int = 0
    @State private var yesterdayScore: Int = 0
    @State private var showDelta: Bool = false
    // Fix W1: Track data confidence for UI rendering
    @State private var confidence: WellnessResult.DataConfidence = .insufficient
    @State private var yesterdayConfidence: WellnessResult.DataConfidence = .insufficient
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "Your pet"
        
        Button(action: {
            onViewTrendsTapped?()
        }) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    // Background Gradient
                RadialGradient(
                    gradient: Gradient(colors: [Color(hex: "#F7F3ED"), Color(hex: "#FFFDF9")]),
                    center: .top,
                    startRadius: 0,
                    endRadius: 200
                )
                
                // Content
                VStack(spacing: 0) {
                    
                    ZStack {

                        // Progress Ring Background
                        Circle()
                            .stroke(Color(hex: "#F5F3EF"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        // Progress Ring Glow
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(ringGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .blur(radius: 12)
                            .opacity(0.6)
                            .animation(.easeOut(duration: 1.0).delay(0.1), value: progress)
                            
                        // Progress Ring Active
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(ringGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.0).delay(0.1), value: progress)
                        
                        // Score Text — Fix W1: show "?" for insufficient data
                        if confidence == .insufficient {
                            VStack(spacing: 2) {
                                Text("—")
                                    .font(.displayLG)
                                    .foregroundColor(.onSurfaceVariant)
                                Text("/100")
                                    .font(.labelMD)
                                    .foregroundColor(.onSurfaceVariant)
                            }
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("\(score)")
                                    .font(.custom("PlusJakartaSans-Bold", size: 56))
                                    .foregroundColor(.primary)
                                    .contentTransition(.numericText(value: Double(score)))
                                Text("/100")
                                    .font(.labelMD)
                                    .foregroundColor(.onSurfaceVariant)
                            }
                        }
                    }
                    .frame(width: 160, height: 160)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Wellness score is \(score) out of 100. \(subtitleText(for: petName))")
                    .accessibilityValue(confidence == .insufficient ? "Data insufficient" : "\(score)")
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    Text(subtitleText(for: petName))
                        .font(.headlineSM)
                        .foregroundColor(.onSurface)
                        .padding(.bottom, 8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: deltaIcon)
                            .font(.bodySM)
                        Text(deltaText)
                            .font(.labelMD)
                    }
                    .foregroundColor(deltaColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(deltaColor.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.bottom, 20)
                    .opacity(showDelta ? 1 : 0)
                    .scaleEffect(showDelta ? 1 : 0.8)
                    
                    HStack(spacing: 4) {
                        Text("View trends")
                            .font(.labelMD)
                        Image(systemName: "chevron.right")
                            .font(.bodySM)
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(
            Color.surfaceContainerLowest
                .overlay(.ultraThinMaterial.opacity(0.5))
        )
        .cornerRadius(AppRadius.card)
        .warmShadow()
        }
        .buttonStyle(SquishyCardStyle())
        .onChange(of: progress) { old, new in
            if new == CGFloat(score) / 100.0 && new > 0 {
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred()
            }
        }
        .onChange(of: logStore.logs.count, initial: true) { old, new in
            calculateDynamicScore()
        }
        .onChange(of: medicationStore.medications.count, initial: true) { old, new in
            calculateDynamicScore()
        }
        .onChange(of: petStore.activePet?.id, initial: true) { old, new in
            calculateDynamicScore()
        }
    }
    
    private func calculateDynamicScore() {
        let relevantLogs = logStore.logs
        let result = WellnessCalculator.calculateScore(logs: relevantLogs, medications: medicationStore.medications)
        
        let yesterday = Date().addingTimeInterval(-24 * 3600)
        let yesterdayResult = WellnessCalculator.calculateScore(logs: relevantLogs, medications: medicationStore.medications, upTo: yesterday)
        
        self.confidence = result.confidence
        self.yesterdayScore = yesterdayResult.score
        self.yesterdayConfidence = yesterdayResult.confidence
        self.progress = confidence == .insufficient ? 0 : CGFloat(result.score) / 100.0
        
        withAnimation(.spring(response: 1.0, dampingFraction: 1.0).delay(0.1)) {
            self.score = result.score
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
            self.showDelta = confidence != .insufficient
        }
    }
    
    // Dynamic Properties
    private var ringGradient: AngularGradient {
        let baseColor: Color
        if confidence == .insufficient { baseColor = Color(hex: "#F5F3EF") }
        else if score >= 80 { baseColor = .primary }
        else if score >= 60 { baseColor = .warning }
        else { baseColor = .error }
        
        return AngularGradient(
            gradient: Gradient(colors: [baseColor.opacity(0.6), baseColor]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }
    
    private func subtitleText(for name: String) -> String {
        if confidence == .insufficient { return "Log more to see \(name)'s score" }
        if confidence == .low { return "Building \(name)'s score…" }
        if score >= 80 { return "\(name)'s having a great day ✨" }
        if score >= 60 { return "\(name) is having a steady day" }
        return "\(name) needs some attention ❤️"
    }
    
    private var deltaValue: Int {
        return score - yesterdayScore
    }
    
    private var deltaIcon: String {
        if confidence == .insufficient || yesterdayConfidence == .insufficient { return "ellipsis" }
        if deltaValue > 0 { return "arrow.up.right" }
        if deltaValue < 0 { return "arrow.down.right" }
        return "arrow.right"
    }
    
    private var deltaText: String {
        if confidence == .insufficient || yesterdayConfidence == .insufficient { return "Gathering data" }
        if deltaValue > 0 { return "Up \(deltaValue) points from yesterday" }
        if deltaValue < 0 { return "Down \(abs(deltaValue)) points from yesterday" }
        return "Stable from yesterday"
    }
    
    private var deltaColor: Color {
        if confidence == .insufficient || yesterdayConfidence == .insufficient { return .primary }
        if deltaValue > 0 { return .primary }
        if deltaValue < 0 { return .error }
        return .primary
    }
}

#Preview {
    WellnessScoreHero()
        .environmentObject(PetStore())
        .padding()
        .background(Color.background)
}

struct SquishyCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
