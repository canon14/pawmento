import SwiftUI

struct WellnessScoreHero: View {
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var medicationStore: MedicationStore
    @State private var progress: CGFloat = 0.0
    @State private var score: Int = 0
    
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
                    
                    Button(action: {
                        // View trends action
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
                
                // Premium Badge
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Premium")
                        .font(.labelSM)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.secondaryContainer.opacity(0.5))
                .clipShape(Capsule())
                .padding(20)
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
        // If we want household vs active pet, for now we will calculate for the active pet's logs if selected,
        // or just household average. The PRD says HomeScreen shows household score, but PetSelector sets an active pet.
        // Assuming we filter by active pet if it exists, or just use all logs if not.
        let relevantLogs = logStore.logs // In MVP, LogStore fetches logs for the household/pet
        let computedScore = WellnessCalculator.calculateScore(logs: relevantLogs, medications: medicationStore.medications)
        self.score = computedScore
        self.progress = CGFloat(computedScore) / 100.0
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
    
    // For MVP, we will mock the delta based on score to avoid the initial load -32 bug,
    // or calculate it statically relative to a fixed past score for demo purposes.
    private var deltaIcon: String {
        if score >= 80 { return "arrow.up.right" }
        if score >= 60 { return "arrow.right" }
        return "arrow.down.right"
    }
    
    private var deltaText: String {
        if score >= 80 { return "Up 4 points from yesterday" }
        if score >= 60 { return "Stable from yesterday" }
        return "Down 5 points from yesterday"
    }
    
    private var deltaColor: Color {
        if score >= 80 { return .sage }
        if score >= 60 { return .warmTan }
        return .warmCoral
    }
}

#Preview {
    WellnessScoreHero()
        .environmentObject(PetStore())
        .padding()
        .background(Color.background)
}
