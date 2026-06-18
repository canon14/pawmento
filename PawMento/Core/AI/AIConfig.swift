import Foundation

enum AIConfig {
    static let haikuModel = "claude-haiku-4-5-20251001"
    static let anthropicVersion = "2023-06-01"
    static let requestTimeout: TimeInterval = 30.0
    static let maxRetries: Int = 3
}
