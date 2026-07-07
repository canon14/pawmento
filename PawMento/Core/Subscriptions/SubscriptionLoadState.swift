import Foundation

enum SubscriptionLoadState: Equatable {
  case unknown
  case loaded
  case failed
}

enum SubscriptionCache {
  private static let isPremiumKey = "subscription_cache_is_premium"

  static var cachedIsPremium: Bool? {
    guard UserDefaults.standard.object(forKey: isPremiumKey) != nil else { return nil }
    return UserDefaults.standard.bool(forKey: isPremiumKey)
  }

  static func save(isPremium: Bool) {
    UserDefaults.standard.set(isPremium, forKey: isPremiumKey)
  }

  static func clear() {
    UserDefaults.standard.removeObject(forKey: isPremiumKey)
  }
}

struct SubscriptionSnapshot: Equatable {
  let isPremium: Bool
  let freeQuestionsRemaining: Int
  let resetLowQuotaWarning: Bool
}
