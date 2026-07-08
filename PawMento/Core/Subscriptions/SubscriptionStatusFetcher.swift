import Foundation
import Supabase

enum SubscriptionStatusFetcher {
  /// When set (tests), redirects subscription fetch instead of Supabase.
  static var fetchHandler: ((UUID) async throws -> SubscriptionSnapshot)?

  private struct SubscriptionDTO: Codable {
    let status: String
    let plan_type: String
    let questions_used: Int
    let period_start: Date
    let current_period_end: Date?
  }

  @MainActor
  static func fetch(ownerId: UUID) async throws -> SubscriptionSnapshot {
    if let fetchHandler {
      return try await fetchHandler(ownerId)
    }

    let sub = try await loadSubscription(ownerId: ownerId, bootstrapIfMissing: true)
    return try await snapshot(from: sub)
  }

  @MainActor
  private static func loadSubscription(ownerId: UUID, bootstrapIfMissing: Bool) async throws -> SubscriptionDTO {
    var rows: [SubscriptionDTO] = try await SupabaseManager.shared.client
      .from("subscriptions")
      .select()
      .eq("user_id", value: ownerId.uuidString)
      .limit(1)
      .execute()
      .value

    if rows.isEmpty && bootstrapIfMissing {
      try await UserBootstrap.ensure()
      rows = try await SupabaseManager.shared.client
        .from("subscriptions")
        .select()
        .eq("user_id", value: ownerId.uuidString)
        .limit(1)
        .execute()
        .value
    }

    guard let sub = rows.first else {
      throw NSError(
        domain: "SubscriptionStatusFetcher",
        code: 404,
        userInfo: [NSLocalizedDescriptionKey: "No subscription row for user"]
      )
    }
    return sub
  }

  @MainActor
  private static func snapshot(from sub: SubscriptionDTO) async throws -> SubscriptionSnapshot {
    let isPremium = SubscriptionEntitlement.isPremium(
      planType: sub.plan_type,
      status: sub.status,
      periodEnd: sub.current_period_end
    )

    if isPremium {
      return SubscriptionSnapshot(
        isPremium: true,
        freeQuestionsRemaining: SubscriptionEntitlement.unlimitedCoachQuota,
        resetLowQuotaWarning: false
      )
    }

    let now = Date()
    let thirtyDays: TimeInterval = 30 * 24 * 60 * 60

    if now.timeIntervalSince(sub.period_start) >= thirtyDays {
      var remaining = SubscriptionEntitlement.freeCoachQuestionQuotaPerPeriod
      do {
        remaining = try await SupabaseManager.shared.client
          .rpc("reset_question_period")
          .execute()
          .value
      } catch {
        print("Failed to reset quota on server: \(error)")
      }

      return SubscriptionSnapshot(
        isPremium: false,
        freeQuestionsRemaining: remaining,
        resetLowQuotaWarning: true
      )
    }

    return SubscriptionSnapshot(
      isPremium: false,
      freeQuestionsRemaining: SubscriptionEntitlement.freeQuestionsRemaining(
        questionsUsed: sub.questions_used
      ),
      resetLowQuotaWarning: false
    )
  }
}
