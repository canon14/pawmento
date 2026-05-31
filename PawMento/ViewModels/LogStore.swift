import Foundation
import Combine
import SwiftUI

@MainActor
class LogStore: ObservableObject {
    @Published var logs: [LogEntry] = []
    
    // Local-first save logic
    func saveLog(_ log: LogEntry) {
        // 1. Insert locally
        logs.insert(log, at: 0)
        
        // 2. Remember last used category for this pet
        let key = "lastUsedCategory_\(log.petId.uuidString)"
        UserDefaults.standard.set(log.category.rawValue, forKey: key)
        
        // 3. Mock sync to backend
        print("Mock: Saved log \(log.id) locally. SyncEngine queued for upload.")
    }
    
    func getLastUsedCategory(for petId: UUID) -> LogCategory? {
        let key = "lastUsedCategory_\(petId.uuidString)"
        if let rawValue = UserDefaults.standard.string(forKey: key) {
            return LogCategory(rawValue: rawValue)
        }
        return nil
    }
}
