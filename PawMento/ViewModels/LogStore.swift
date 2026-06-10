import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
class LogStore: ObservableObject {
    @Published var logs: [LogEntry] = []
    
    // Local-first save logic with Supabase Sync
    @MainActor
    func saveLog(_ log: LogEntry, userId: UUID) async {
        // 1. Insert locally for immediate UI update
        logs.insert(log, at: 0)
        
        // 2. Remember last used category for this pet
        let key = "lastUsedCategory_\(log.petId.uuidString)"
        UserDefaults.standard.set(log.category.rawValue, forKey: key)
        
        // 3. Sync to Supabase
        var finalLog = log
        do {
            if let image = log.photoImage {
                let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
                let urlString = try await StorageManager.shared.uploadImage(image, path: path)
                finalLog.photoLocalURL = URL(string: urlString)
                
                // Update local model with the URL
                if let index = logs.firstIndex(where: { $0.id == finalLog.id }) {
                    logs[index].photoLocalURL = finalLog.photoLocalURL
                }
            }
            
            let dto = finalLog.toDTO(userId: userId)
            try await SupabaseManager.shared.client
                .from("logs")
                .insert(dto)
                .execute()
                
            // Mark synced
            if let index = logs.firstIndex(where: { $0.id == finalLog.id }) {
                logs[index].syncedAt = Date()
            }
        } catch {
            print("Failed to sync log to Supabase: \(error)")
            // Save image locally for offline queue
            var offlineLog = finalLog
            if let image = log.photoImage, 
               let localURL = StorageManager.shared.saveImageToDisk(image, fileName: "\(offlineLog.id.uuidString).jpg") {
                offlineLog.photoLocalURL = localURL
                
                // Update local model with the local disk URL
                if let index = logs.firstIndex(where: { $0.id == finalLog.id }) {
                    logs[index].photoLocalURL = localURL
                }
            }
            
            // It remains local-only for now, but we queue it for later!
            OfflineSyncManager.shared.enqueueTask(.createLog(offlineLog, userId))
        }
    }
    
    @MainActor
    func updateLog(_ log: LogEntry, userId: UUID) async {
        // 1. Update locally for immediate UI update
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
        }
        
        // 2. Sync to Supabase
        var finalLog = log
        do {
            if let image = log.photoImage {
                let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
                let urlString = try await StorageManager.shared.uploadImage(image, path: path)
                finalLog.photoLocalURL = URL(string: urlString)
                
                if let index = logs.firstIndex(where: { $0.id == finalLog.id }) {
                    logs[index].photoLocalURL = finalLog.photoLocalURL
                }
            }
            
            let dto = finalLog.toDTO(userId: userId)
            try await SupabaseManager.shared.client
                .from("logs")
                .update(dto)
                .eq("id", value: log.id.uuidString)
                .execute()
                
            // Mark synced
            if let index = logs.firstIndex(where: { $0.id == finalLog.id }) {
                logs[index].syncedAt = Date()
            }
        } catch {
            print("Failed to sync updated log to Supabase: \(error)")
            
            var offlineLog = finalLog
            if let image = log.photoImage, 
               let localURL = StorageManager.shared.saveImageToDisk(image, fileName: "\(offlineLog.id.uuidString).jpg") {
                offlineLog.photoLocalURL = localURL
                if let index = logs.firstIndex(where: { $0.id == finalLog.id }) {
                    logs[index].photoLocalURL = localURL
                }
            }
            
            OfflineSyncManager.shared.enqueueTask(.updateLog(offlineLog, userId))
        }
    }
    
    @MainActor
    func deleteLog(_ log: LogEntry, userId: UUID) async {
        // 1. Remove locally
        logs.removeAll { $0.id == log.id }
        
        // 2. Delete from Supabase
        do {
            try await SupabaseManager.shared.client
                .from("logs")
                .delete()
                .eq("id", value: log.id.uuidString)
                .execute()
                
            // Clean up photo if exists
            if log.photoLocalURL != nil {
                let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
                try? await StorageManager.shared.deleteImage(path: path)
            }
        } catch {
            print("Failed to delete log from Supabase: \(error)")
            OfflineSyncManager.shared.enqueueTask(.deleteLog(log.id, userId))
        }
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
}
