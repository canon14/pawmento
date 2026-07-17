import SwiftUI

struct WellnessScoreHero: View {
    var ringMode: WellnessRingMode
    var shouldPlayUnlockAnimation: Bool = false
    var onUnlockAnimationComplete: (() -> Void)? = nil
    var onViewTrendsTapped: (() -> Void)? = nil
    var onAddPet: (() -> Void)? = nil
    
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var medicationStore: MedicationStore
    
    @State private var progress: CGFloat = 0.0
    @State private var score: Int = 0
    @State private var yesterdayScore: Int = 0
    @State private var showDelta: Bool = false
    @State private var confidence: WellnessResult.DataConfidence = .insufficient
    @State private var yesterdayConfidence: WellnessResult.DataConfidence = .insufficient
    @State private var isSetupMode = true
    @State private var setupCenterLabel = "Getting started"
    @State private var setupSubtitle = "Log your first entry"
    @State private var unlockScale: CGFloat = 1.0
    @State private var unlockOpacity: Double = 1.0
    @State private var showPetSwitcher = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RadialGradient(
                    gradient: Gradient(colors: backgroundGradientColors),
                    center: .top,
                    startRadius: 0,
                    endRadius: 220
                )
                
                VStack(spacing: 0) {
                    petIdentityRow
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    Button(action: {
                        onViewTrendsTapped?()
                    }) {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .stroke(Color(hex: "#F5F3EF"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(ringGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .blur(radius: 12)
                                    .opacity(0.6)
                                    .animation(.easeOut(duration: 1.0).delay(0.1), value: progress)
                                
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(ringGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeOut(duration: 1.0).delay(0.1), value: progress)
                                
                                if isSetupMode {
                                    VStack(spacing: 4) {
                                        Text(setupCenterLabel)
                                            .font(.headlineMD)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                        Text("Setup progress")
                                            .font(.labelSM)
                                            .foregroundColor(.onSurfaceVariant)
                                    }
                                    .padding(.horizontal, 8)
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
                            .scaleEffect(unlockScale)
                            .opacity(unlockOpacity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(accessibilityRingLabel)
                            .padding(.top, 28)
                            .padding(.bottom, 20)
                            
                            Text(isSetupMode ? setupSubtitle : subtitleText(for: score))
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
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(SquishyCardStyle())
                }
            }
        }
        .background(
            Color.surfaceContainerLowest
                .overlay(.ultraThinMaterial.opacity(0.5))
        )
        .cornerRadius(AppRadius.card)
        .warmShadow()
        .confirmationDialog("Switch Pet", isPresented: $showPetSwitcher, titleVisibility: .visible) {
            ForEach(petStore.pets) { pet in
                Button(pet.id == petStore.activePet?.id ? "\(pet.name) ✓" : pet.name) {
                    petStore.activePet = pet
                }
            }
        }
        .onChange(of: ringMode) { _, newMode in
            applyRingMode(newMode, animated: true)
        }
        .onChange(of: shouldPlayUnlockAnimation) { _, shouldPlay in
            guard shouldPlay else { return }
            playUnlockTransition()
        }
        .onAppear {
            applyRingMode(ringMode, animated: false)
        }
        .onChange(of: logStore.logs.count) { _, _ in
            updateYesterdayComparison()
        }
        .onChange(of: medicationStore.medications.count) { _, _ in
            updateYesterdayComparison()
        }
    }
    
    // MARK: - Pet Identity
    
    private var petIdentityRow: some View {
        HStack(spacing: 12) {
            Button {
                if petStore.pets.count > 1 {
                    showPetSwitcher = true
                }
            } label: {
                HStack(spacing: 12) {
                    petAvatar
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [Color.primary, Color.primary.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        )
                        .shadow(color: Color.primary.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    HStack(spacing: 6) {
                        Text(petStore.activePet?.name ?? "No Pet")
                            .font(.headlineSM)
                            .fontWeight(.bold)
                            .foregroundColor(.onSurface)
                            .lineLimit(1)
                        
                        if petStore.pets.count > 1 {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.onSurfaceVariant)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(petStore.pets.count <= 1)
            .accessibilityLabel(petStore.activePet.map { "\($0.name), active pet" } ?? "No pet selected")
            .accessibilityHint(petStore.pets.count > 1 ? "Double tap to switch pets" : "")
            
            Spacer(minLength: 8)
            
            if let onAddPet {
                Button(action: onAddPet) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Color.primaryContainer.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(SquishyCardStyle())
                .accessibilityLabel("Add pet")
            }
        }
    }
    
    @ViewBuilder
    private var petAvatar: some View {
        if let pet = petStore.activePet, let image = pet.photoImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let pet = petStore.activePet, let photoURL = pet.photoLocalURL {
            CachedAsyncImage(url: photoURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ZStack {
                    Color.surfaceContainerHigh
                    ProgressView()
                }
            }
        } else {
            ZStack {
                Color.surfaceContainerHigh
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.primary.opacity(0.6))
            }
        }
    }
    
    private var backgroundGradientColors: [Color] {
        if isSetupMode {
            return [Color.primaryContainer.opacity(0.25), Color(hex: "#FFFDF9")]
        }
        return [Color(hex: "#F7F3ED"), Color(hex: "#FFFDF9")]
    }
    
    private var accessibilityRingLabel: String {
        if isSetupMode {
            return "Setup progress \(setupCenterLabel). \(setupSubtitle)"
        }
        return "Wellness score is \(score) out of 100. \(subtitleText(for: score))"
    }
    
    private func applyRingMode(_ mode: WellnessRingMode, animated: Bool) {
        switch mode {
        case .setupProgress(let setup):
            isSetupMode = true
            setupCenterLabel = setup.centerLabel
            setupSubtitle = setup.nextActionLabel
            let target = CGFloat(setup.completedCount) / CGFloat(SetupProgress.totalSteps)
            if animated {
                withAnimation(.easeOut(duration: 1.0).delay(0.1)) {
                    self.progress = target
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showDelta = false
                }
            } else {
                self.progress = target
                showDelta = false
            }
        case .score(let result):
            isSetupMode = false
            confidence = result.confidence
            let target = CGFloat(result.score) / 100.0
            if animated {
                withAnimation(.spring(response: 1.0, dampingFraction: 1.0).delay(0.1)) {
                    score = result.score
                    progress = target
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
                    showDelta = true
                }
            } else {
                score = result.score
                progress = target
                showDelta = true
            }
            updateYesterdayComparison()
        }
    }
    
    private func playUnlockTransition() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            unlockScale = 1.08
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                unlockScale = 1.0
            }
            onUnlockAnimationComplete?()
        }
    }
    
    private func updateYesterdayComparison() {
        guard !isSetupMode else { return }
        let yesterday = Date().addingTimeInterval(-24 * 3600)
        let yesterdayResult = WellnessCalculator.calculateScore(
            logs: logStore.logs,
            medications: medicationStore.medications,
            upTo: yesterday
        )
        yesterdayScore = yesterdayResult.score
        yesterdayConfidence = yesterdayResult.confidence
    }
    
    private var ringGradient: AngularGradient {
        let baseColor: Color
        if isSetupMode {
            baseColor = .primary
        } else if score >= 80 {
            baseColor = .primary
        } else if score >= 60 {
            baseColor = .warning
        } else {
            baseColor = .error
        }
        
        return AngularGradient(
            gradient: Gradient(colors: [baseColor.opacity(0.6), baseColor]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }
    
    private func subtitleText(for score: Int) -> String {
        if confidence == .low { return "Building your pet's score…" }
        if score >= 80 { return "Having a great day ✨" }
        if score >= 60 { return "Having a steady day" }
        return "Needs some attention ❤️"
    }
    
    private var deltaValue: Int {
        score - yesterdayScore
    }
    
    private var deltaIcon: String {
        if isSetupMode { return "sparkles" }
        if yesterdayConfidence == .insufficient { return "ellipsis" }
        if deltaValue > 0 { return "arrow.up.right" }
        if deltaValue < 0 { return "arrow.down.right" }
        return "arrow.right"
    }
    
    private var deltaText: String {
        if isSetupMode { return "Earn your wellness score" }
        if yesterdayConfidence == .insufficient { return "Gathering data" }
        if deltaValue > 0 { return "Up \(deltaValue) points from yesterday" }
        if deltaValue < 0 { return "Down \(abs(deltaValue)) points from yesterday" }
        return "Stable from yesterday"
    }
    
    private var deltaColor: Color {
        if isSetupMode { return .primary }
        if deltaValue < 0 { return .error }
        return .primary
    }
}

// MARK: - Previews

#Preview("Setup 1/4") {
    let progress = SetupProgress(
        hasPet: true,
        hasFirstLog: false,
        hasThreeDaysLogged: false,
        hasFirstInsight: false,
        distinctDaysLogged: 0,
        petName: "Luna"
    )
    return WellnessScoreHero(ringMode: .setupProgress(progress), onAddPet: {})
        .environmentObject(PetStore())
        .environmentObject(LogStore())
        .environmentObject(MedicationStore())
        .padding()
        .background(Color.background)
}

#Preview("Setup 3/4") {
    let progress = SetupProgress(
        hasPet: true,
        hasFirstLog: true,
        hasThreeDaysLogged: true,
        hasFirstInsight: false,
        distinctDaysLogged: 3,
        petName: "Luna"
    )
    return WellnessScoreHero(ringMode: .setupProgress(progress), onAddPet: {})
        .environmentObject(PetStore())
        .environmentObject(LogStore())
        .environmentObject(MedicationStore())
        .padding()
        .background(Color.background)
}

#Preview("Score mode") {
    let result = WellnessResult(score: 82, confidence: .sufficient)
    return WellnessScoreHero(ringMode: .score(result), onAddPet: {})
        .environmentObject(PetStore())
        .environmentObject(LogStore())
        .environmentObject(MedicationStore())
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
