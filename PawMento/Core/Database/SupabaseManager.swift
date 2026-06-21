import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Fix 8: Safe URL init — fail with a clear message instead of a cryptic crash
        guard let supabaseURL = URL(string: Secrets.supabaseURL) else {
            fatalError("Invalid Secrets.supabaseURL — configure Secrets.swift")
        }
        let supabaseKey = Secrets.supabaseAnonKey
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
