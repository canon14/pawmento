import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
class LogStore: ObservableObject {
    @Published var logs: [LogEntry] = []
    
    // Online-only save logic
    @MainActor
    func saveLog(_ log: LogEntry, userId: UUID) async throws {
        // 1. Upload photo if exists
        var finalLog = log
        if let image = log.photoImage {
            let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
            // Fix 2: uploadImage returns bucket-relative path; derive public URL for display
            let relativePath = try await StorageManager.shared.uploadImage(image, path: path)
            finalLog.photoLocalURL = StorageManager.shared.publicURL(forPath: relativePath)
        }
        
        // 2. Sync to Supabase
        let dto = finalLog.toDTO(userId: userId)
        try await SupabaseManager.shared.client
            .from("logs")
            .insert(dto)
            .execute()
            
        finalLog.syncedAt = Date()
        
        // 3. Update local array after success to prevent race condition with fetchLogs
        logs.append(finalLog)
        logs.sort(by: { $0.recordedAt > $1.recordedAt })
        
        // 4. Remember last used category for this pet
        let key = "lastUsedCategory_\(log.petId.uuidString)"
        UserDefaults.standard.set(log.category.rawValue, forKey: key)
    }
    
    @MainActor
    func updateLog(_ log: LogEntry, userId: UUID) async throws {
        // 1. Upload photo if it's new/updated
        var finalLog = log
        if let image = log.photoImage {
            let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
            // Fix 2: uploadImage returns bucket-relative path; derive public URL for display
            let relativePath = try await StorageManager.shared.uploadImage(image, path: path)
            finalLog.photoLocalURL = StorageManager.shared.publicURL(forPath: relativePath)
        }
        
        // 2. Sync to Supabase
        let dto = finalLog.toUpdateDTO()
        try await SupabaseManager.shared.client
            .from("logs")
            .update(dto)
            .eq("id", value: log.id.uuidString)
            .execute()
            
        finalLog.syncedAt = Date()
        
        // 3. Update local array after success
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = finalLog
            logs.sort(by: { $0.recordedAt > $1.recordedAt })
        }
    }
    
    @MainActor
    func deleteLog(_ log: LogEntry, userId: UUID) async throws {
        // 1. Delete from Supabase
        try await SupabaseManager.shared.client
            .from("logs")
            .delete()
            .eq("id", value: log.id.uuidString)
            .execute()
            
        // 2. Clean up remote photo if exists
        if log.photoLocalURL != nil {
            let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
            try? await StorageManager.shared.deleteImage(path: path)
        }
        
        // 3. Remove locally after success
        logs.removeAll { $0.id == log.id }
    }
    
    @MainActor
    func fetchLogs(for petId: UUID) async {
        do {
            let dtos: [LogDTO] = try await SupabaseManager.shared.client
                .from("logs")
                .select()
                .eq("pet_id", value: petId.uuidString)
                .order("timestamp", ascending: false)
                .execute()
                .value
            
            self.logs = dtos.map { $0.toLogEntry() }
        } catch {
            print("Failed to fetch logs: \(error)")
        }
    }
    
    func getLastUsedCategory(for petId: UUID) -> LogCategory? {
        let key = "lastUsedCategory_\(petId.uuidString)"
        if let rawValue = UserDefaults.standard.string(forKey: key) {
            return LogCategory(rawValue: rawValue)
        }
        return nil
    }
    
    @MainActor
    func reset() {
        logs = []
    }
}
