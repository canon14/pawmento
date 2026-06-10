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
    
    var body: some View {
        let petName = petStore.activePet?.name ?? "Your pet"
        
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
                        
                        // Progress Ring Active
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(ringColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .shadow(color: ringColor.opacity(0.4), radius: 8, x: 0, y: 0)
                            .animation(.easeOut(duration: 1.0).delay(0.1), value: progress)
                        
                        // Score Text
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(score)")
                                .font(.headlineXL)
                                .foregroundColor(.primary)
                            Text("/100")
                                .font(.labelMD)
                                .foregroundColor(.onSurfaceVariant)
                        }
                    }
                    .frame(width: 160, height: 160)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    Text(subtitleText(for: petName))
                        .font(.headlineSM)
                        .foregroundColor(.onSurface)
                        .padding(.bottom, 8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: deltaIcon)
                            .font(.system(size: 14, weight: .bold))
                        Text(deltaText)
                            .font(.labelMD)
                    }
                    .foregroundColor(deltaColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(deltaColor.opacity(0.15))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .opacity(showDelta ? 1 : 0)
                    .scaleEffect(showDelta ? 1 : 0.8)
                    
                    Button(action: {
                        onViewTrendsTapped?()
                    }) {
                        HStack(spacing: 4) {
                            Text("View trends")
                                .font(.labelMD)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.surfaceContainerLowest)
        .cornerRadius(24)
        .warmShadow()
        .onAppear {
            calculateDynamicScore()
        }
        .onChange(of: logStore.logs.count) { _ in
            calculateDynamicScore()
        }
        .onChange(of: medicationStore.medications.count) { _ in
            calculateDynamicScore()
        }
        .onChange(of: petStore.activePet?.id) { _ in
            calculateDynamicScore()
        }
    }
    
    private func calculateDynamicScore() {
        let relevantLogs = logStore.logs // In MVP, LogStore fetches logs for the household/pet
        let computedScore = WellnessCalculator.calculateScore(logs: relevantLogs, medications: medicationStore.medications)
        
        let yesterday = Date().addingTimeInterval(-24 * 3600)
        let yesterdayComputedScore = WellnessCalculator.calculateScore(logs: relevantLogs, medications: medicationStore.medications, upTo: yesterday)
        
        self.score = computedScore
        self.yesterdayScore = yesterdayComputedScore
        self.progress = CGFloat(computedScore) / 100.0
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
            self.showDelta = true
        }
    }
    
    // Dynamic Properties
    private var ringColor: Color {
        if score >= 80 { return .sage }
        if score >= 60 { return .warmTan }
        return .warmCoral
    }
    
    private func subtitleText(for name: String) -> String {
        if score >= 80 { return "\(name)'s having a great day ✨" }
        if score >= 60 { return "\(name) is having a steady day" }
        return "\(name) needs some attention ❤️"
    }
    
    private var deltaValue: Int {
        return score - yesterdayScore
    }
    
    private var deltaIcon: String {
        if deltaValue > 0 { return "arrow.up.right" }
        if deltaValue < 0 { return "arrow.down.right" }
        return "arrow.right"
    }
    
    private var deltaText: String {
        if deltaValue > 0 { return "Up \(deltaValue) points from yesterday" }
        if deltaValue < 0 { return "Down \(abs(deltaValue)) points from yesterday" }
        return "Stable from yesterday"
    }
    
    private var deltaColor: Color {
        if deltaValue > 0 { return .sage }
        if deltaValue < 0 { return .warmCoral }
        return .warmTan
    }
}

#Preview {
    WellnessScoreHero()
        .environmentObject(PetStore())
        .padding()
        .background(Color.background)
}
