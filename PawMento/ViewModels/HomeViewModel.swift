import Foundation
import SwiftUI
import Combine

// MARK: - Setup ladder (P2)

struct SetupProgress: Equatable {
    static let totalSteps = 4
    
    let hasPet: Bool
    let hasFirstLog: Bool
    let hasThreeDaysLogged: Bool
    let hasFirstInsight: Bool
    let distinctDaysLogged: Int
    let petName: String
    
    var completedCount: Int {
        var count = 0
        if hasPet { count += 1 }
        if hasFirstLog { count += 1 }
        if hasThreeDaysLogged { count += 1 }
        if hasFirstInsight { count += 1 }
        return count
    }
    
    var nextActionLabel: String {
        if !hasFirstLog {
            return "Log your first entry"
        }
        if !hasThreeDaysLogged {
            return "Log on 3 different days"
        }
        if !hasFirstInsight {
            return "Keep logging to unlock your first pattern"
        }
        return "Setup complete"
    }
    
    var centerLabel: String {
        if completedCount == 0 {
            return "Getting started"
        }
        return "Setup \(completedCount)/\(Self.totalSteps)"
    }
    
    static func compute(pet: Pet?, logs: [LogEntry], hasFirstInsight: Bool) -> SetupProgress {
        let distinctDays = InsightCalendar.distinctDayCount(for: logs.map(\.recordedAt))
        return SetupProgress(
            hasPet: pet != nil,
            hasFirstLog: !logs.isEmpty,
            hasThreeDaysLogged: distinctDays >= 3,
            hasFirstInsight: hasFirstInsight,
            distinctDaysLogged: distinctDays,
            petName: pet?.name ?? PetStore.fallbackPetName
        )
    }
}

enum WellnessRingMode: Equatable {
    case setupProgress(SetupProgress)
    case score(WellnessResult)
}

// MARK: - Habit loop (P3)

enum CelebrationState: Equatable {
    case none
    case firstLog
    case firstInsight
}

enum TodaysOneThing: Equatable {
    case nudge(String)
    case done
}

// MARK: - Home orchestration

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var ringMode: WellnessRingMode = .setupProgress(
        SetupProgress.compute(pet: nil, logs: [], hasFirstInsight: false)
    )
    @Published private(set) var setupProgress: SetupProgress = SetupProgress.compute(
        pet: nil, logs: [], hasFirstInsight: false
    )
    @Published private(set) var shouldPlayUnlockAnimation = false
    
    @Published var hasFirstInsight = false
    
    @Published private(set) var celebration: CelebrationState = .none
    @Published private(set) var loggingStreak: Int = 0
    @Published private(set) var todaysOneThing: TodaysOneThing?
    @Published var pendingStrongInsightPaywall: Insight?
    
    private var previousWasInsufficient = true
    private var previousLogCount = 0
    private var hasSeededLogCount = false
    private var previousHasFirstInsight = false
    private var hasSeededFirstInsight = false
    private var pendingFirstInsightCelebration = false
    private var trackedPetId: UUID?
    
    private static let firstLogCelebrationPrefix = "firstLogCelebrationShown_"
    private static let firstInsightCelebrationPrefix = "firstInsightCelebrationShown_"
    
    func refresh(
        pet: Pet?,
        logs: [LogEntry],
        medications: [Medication],
        isFetchingLogs: Bool = false
    ) {
        if pet?.id != trackedPetId {
            trackedPetId = pet?.id
            hasSeededLogCount = false
            previousLogCount = 0
            hasSeededFirstInsight = false
            previousHasFirstInsight = false
            pendingFirstInsightCelebration = false
            celebration = .none
            previousWasInsufficient = true
            shouldPlayUnlockAnimation = false
        }
        
        let newCount = logs.count
        
        if let petId = pet?.id {
            seedAndEvaluateFirstLogCelebration(
                petId: petId,
                newCount: newCount,
                isFetchingLogs: isFetchingLogs
            )
        } else {
            previousLogCount = newCount
            hasSeededLogCount = true
        }
        
        let progress = SetupProgress.compute(
            pet: pet,
            logs: logs,
            hasFirstInsight: hasFirstInsight
        )
        setupProgress = progress
        
        loggingStreak = InsightCalendar.consecutiveLoggingStreak(for: logs.map(\.recordedAt))
        todaysOneThing = Self.computeTodaysOneThing(petName: progress.petName, logs: logs)
        
        let result = WellnessCalculator.calculateScore(
            logs: logs,
            medications: medications
        )
        let isInsufficient = result.confidence == .insufficient
        
        if isInsufficient {
            ringMode = .setupProgress(progress)
            shouldPlayUnlockAnimation = false
            previousWasInsufficient = true
        } else {
            if previousWasInsufficient {
                shouldPlayUnlockAnimation = true
            }
            ringMode = .score(result)
            previousWasInsufficient = false
        }
    }
    
    func updateHasFirstInsight(_ value: Bool, for petId: UUID) {
        if !hasSeededFirstInsight && value {
            Self.markCelebratedFirstInsight(for: petId)
        }
        
        let previous = hasSeededFirstInsight ? previousHasFirstInsight : value
        
        if !previous && value && !Self.hasCelebratedFirstInsight(for: petId) {
            if celebration == .firstLog {
                pendingFirstInsightCelebration = true
            } else {
                celebration = .firstInsight
            }
            Self.markCelebratedFirstInsight(for: petId)
        }
        
        previousHasFirstInsight = value
        hasFirstInsight = value
        hasSeededFirstInsight = true
    }
    
    func acknowledgeUnlockAnimation() {
        shouldPlayUnlockAnimation = false
    }
    
    func acknowledgeCelebration() {
        if celebration == .firstLog && pendingFirstInsightCelebration {
            pendingFirstInsightCelebration = false
            celebration = .firstInsight
        } else {
            celebration = .none
            pendingFirstInsightCelebration = false
        }
    }
    
    func presentFirstStrongInsightPaywallIfEligible(insight: Insight?, userId: UUID, isPremium: Bool) {
        guard !isPremium, let insight, insight.tier == .strong else { return }
        guard PaywallEventGate.claimFirstStrongInsightIfEligible(userId: userId) else { return }
        pendingStrongInsightPaywall = insight
    }
    
    func acknowledgeStrongInsightPaywall() {
        pendingStrongInsightPaywall = nil
    }
    
    // MARK: - First-log celebration
    
    private func seedAndEvaluateFirstLogCelebration(
        petId: UUID,
        newCount: Int,
        isFetchingLogs: Bool
    ) {
        if !hasSeededLogCount {
            if isFetchingLogs && newCount == 0 {
                // Wait for fetch completion or an in-flight first save before seeding.
                return
            }
            
            if isFetchingLogs && newCount >= 1 {
                // First save beat the fetch — treat as 0→1 so celebration still fires.
                evaluateFirstLogCelebration(petId: petId, previousCount: 0, newCount: newCount)
                previousLogCount = newCount
                hasSeededLogCount = true
                return
            }
            
            // Fetch completed: existing history must never get a late first-log celebration.
            if newCount >= 1 {
                Self.markCelebratedFirstLog(for: petId)
            }
            previousLogCount = newCount
            hasSeededLogCount = true
            return
        }
        
        evaluateFirstLogCelebration(
            petId: petId,
            previousCount: previousLogCount,
            newCount: newCount
        )
        previousLogCount = newCount
    }
    
    private func evaluateFirstLogCelebration(petId: UUID, previousCount: Int, newCount: Int) {
        guard previousCount == 0, newCount >= 1 else { return }
        guard !Self.hasCelebratedFirstLog(for: petId) else { return }
        celebration = .firstLog
        Self.markCelebratedFirstLog(for: petId)
    }
    
    private static func hasCelebratedFirstLog(for petId: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: firstLogCelebrationPrefix + petId.uuidString)
    }
    
    private static func markCelebratedFirstLog(for petId: UUID) {
        UserDefaults.standard.set(true, forKey: firstLogCelebrationPrefix + petId.uuidString)
    }
    
    // MARK: - First-insight celebration
    
    private static func hasCelebratedFirstInsight(for petId: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: firstInsightCelebrationPrefix + petId.uuidString)
    }
    
    private static func markCelebratedFirstInsight(for petId: UUID) {
        UserDefaults.standard.set(true, forKey: firstInsightCelebrationPrefix + petId.uuidString)
    }
    
    // MARK: - Today's one thing (local calendar — matches TodayLogGrid)
    
    static func computeTodaysOneThing(petName: String, logs: [LogEntry], now: Date = Date()) -> TodaysOneThing {
        let hasLoggedToday = logs.contains { Calendar.current.isDateInToday($0.recordedAt) }
        if hasLoggedToday {
            return .done
        }
        
        let hour = Calendar.current.component(.hour, from: now)
        let message: String
        if hour < 11 {
            message = "Log breakfast to keep \(petName)'s record complete."
        } else if hour < 17 {
            message = "Log a walk or playtime for \(petName) today."
        } else {
            message = "Log an evening check-in for \(petName)."
        }
        return .nudge(message)
    }
}
