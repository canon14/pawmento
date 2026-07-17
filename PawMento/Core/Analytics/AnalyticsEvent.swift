//
//  AnalyticsEvent.swift
//  PawMento
//
//  Sprint 0 — Provider-agnostic analytics event definitions.
//

import Foundation

/// Every trackable funnel / retention event in PawMento.
///
/// Each case maps to a stable `snake_case` name and a PII-free property dict.
/// Do NOT add free-text, pet names, emails, or photo data to properties.
enum AnalyticsEvent {
    case appOpen(isFirstLaunch: Bool)
    case appReturnDayN(dayIndex: Int)
    case petAdded(species: String, hasPhoto: Bool)
    case wellnessBaselineViewed(scoreBucket: String)
    case coachQuestionSent(isFirstEver: Bool)
    case coachAnswerReceived(wasFree: Bool)
    case signupStarted(method: AuthMethod)
    case signupCompleted(method: AuthMethod)
    case paywallShown(trigger: PaywallTrigger)
    case purchaseCompleted(productId: String)

    // MARK: - Stable event name

    var name: String {
        switch self {
        case .appOpen:                return "app_open"
        case .appReturnDayN:          return "app_return_day_n"
        case .petAdded:               return "pet_added"
        case .wellnessBaselineViewed: return "wellness_baseline_viewed"
        case .coachQuestionSent:      return "coach_question_sent"
        case .coachAnswerReceived:    return "coach_answer_received"
        case .signupStarted:          return "signup_started"
        case .signupCompleted:        return "signup_completed"
        case .paywallShown:           return "paywall_shown"
        case .purchaseCompleted:      return "purchase_completed"
        }
    }

    // MARK: - PII-free properties

    var properties: [String: Any] {
        switch self {
        case .appOpen(let isFirstLaunch):
            return ["is_first_launch": isFirstLaunch]

        case .appReturnDayN(let dayIndex):
            return ["day_index": dayIndex]

        case .petAdded(let species, let hasPhoto):
            return ["species": species, "has_photo": hasPhoto]

        case .wellnessBaselineViewed(let scoreBucket):
            return ["score_bucket": scoreBucket]

        case .coachQuestionSent(let isFirstEver):
            return ["is_first_ever": isFirstEver]

        case .coachAnswerReceived(let wasFree):
            return ["was_free": wasFree]

        case .signupStarted(let method):
            return ["method": method.rawValue]

        case .signupCompleted(let method):
            return ["method": method.rawValue]

        case .paywallShown(let trigger):
            return ["trigger": trigger.rawValue]

        case .purchaseCompleted(let productId):
            return ["product_id": productId]
        }
    }

    // MARK: - Supporting enums

    enum AuthMethod: String {
        case emailSignIn  = "email_sign_in"
        case emailSignUp  = "email_sign_up"
        case apple        = "apple"
    }

    enum PaywallTrigger: String {
        case unlimitedCoaching = "unlimited_coaching"
        case patternAnalysis   = "pattern_analysis"
        case vetPdfReports     = "vet_pdf_reports"
        case timelineExport    = "timeline_export"
        case general           = "general"
    }

    // MARK: - Helpers

    /// Maps a wellness score (0–100) to a display bucket like "80-89".
    static func scoreBucket(for score: Int) -> String {
        let clamped = max(0, min(100, score))
        if clamped == 100 { return "100" }
        let lower = (clamped / 10) * 10
        let upper = lower + 9
        return "\(lower)-\(upper)"
    }

    /// Maps a `PaywallSheet.featureContext` string to a safe enum value.
    static func paywallTrigger(from featureContext: String?) -> PaywallTrigger {
        guard let context = featureContext?.lowercased() else { return .general }
        if context.contains("coaching")  { return .unlimitedCoaching }
        if context.contains("pattern")   { return .patternAnalysis }
        if context.contains("pdf") || context.contains("report") { return .vetPdfReports }
        if context.contains("timeline") || context.contains("export") { return .timelineExport }
        return .general
    }
}
