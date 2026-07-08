import Foundation
import Supabase

/// Ensures `public.users` and `subscriptions` rows exist for the signed-in user.
enum UserBootstrap {
    static func ensure(maxAttempts: Int = 3) async throws {
        var lastError: Error?
        for attempt in 1...maxAttempts {
            do {
                try await SupabaseManager.shared.client
                    .rpc("ensure_user_bootstrap")
                    .execute()
                return
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                }
            }
        }
        throw lastError ?? NSError(
            domain: "UserBootstrap",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to bootstrap user profile"]
        )
    }
}
