import Foundation
import Combine
import UIKit
import Supabase

enum SyncTask: Codable {
    case createLog(LogEntry, UUID) // LogEntry and owner userId
    case createPet(Pet, UUID) // Pet and owner userId
}

@MainActor
class OfflineSyncManager: ObservableObject {
    static let shared = OfflineSyncManager()
    private let queueKey = "pawmento_offline_sync_queue"
    
    @Published var isSyncing = false
    @Published var queuedTaskCount = 0
    
    private var queue: [SyncTask] = []
    
    private init() {
        loadQueue()
    }
    
    func enqueueTask(_ task: SyncTask) {
        queue.append(task)
        saveQueue()
    }
    
    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: queueKey),
           let savedQueue = try? JSONDecoder().decode([SyncTask].self, from: data) {
            self.queue = savedQueue
            self.queuedTaskCount = savedQueue.count
        }
    }
    
    private func saveQueue() {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
            self.queuedTaskCount = queue.count
        }
    }
    
    func flushQueue() {
        guard !isSyncing, !queue.isEmpty else { return }
        
        Task {
            isSyncing = true
            var newQueue = queue // operate on a copy
            
            for task in queue {
                let success = await processTask(task)
                if success {
                    // Remove from queue
                    if let index = newQueue.firstIndex(where: {
                        switch ($0, task) {
                        case (.createLog(let l1, _), .createLog(let l2, _)): return l1.id == l2.id
                        case (.createPet(let p1, _), .createPet(let p2, _)): return p1.id == p2.id
                        default: return false
                        }
                    }) {
                        newQueue.remove(at: index)
                    }
                } else {
                    // Stop flushing on first failure to maintain order, or just break
                    print("Failed to sync a task, stopping queue flush.")
                    break
                }
            }
            
            self.queue = newQueue
            self.saveQueue()
            self.isSyncing = false
        }
    }
    
    private func processTask(_ task: SyncTask) async -> Bool {
        switch task {
        case .createLog(let log, let userId):
            return await syncLog(log, userId: userId)
        case .createPet(let pet, let ownerId):
            return await syncPet(pet, ownerId: ownerId)
        }
    }
    
    private func syncLog(_ log: LogEntry, userId: UUID) async -> Bool {
        var finalLog = log
        do {
            // Check if there's a local photo to upload
            if let localURL = log.photoLocalURL, localURL.isFileURL {
                if let data = try? Data(contentsOf: localURL), let image = UIImage(data: data) {
                    let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
                    let urlString = try await StorageManager.shared.uploadImage(image, path: path)
                    finalLog.photoLocalURL = URL(string: urlString)
                    
                    // Clean up local file after successful upload
                    try? FileManager.default.removeItem(at: localURL)
                }
            }
            
            let dto = finalLog.toDTO(userId: userId)
            try await SupabaseManager.shared.client
                .from("logs")
                .insert(dto)
                .execute()
            
            return true
        } catch {
            print("Sync failed for log \(log.id): \(error)")
            return false
        }
    }
    
    private func syncPet(_ pet: Pet, ownerId: UUID) async -> Bool {
        var finalPet = pet
        do {
            // Check if there's a local photo to upload
            if let localURL = pet.photoLocalURL, localURL.isFileURL {
                if let data = try? Data(contentsOf: localURL), let image = UIImage(data: data) {
                    let path = "pets/\(ownerId.uuidString)/\(pet.id.uuidString).jpg"
                    let urlString = try await StorageManager.shared.uploadImage(image, path: path)
                    finalPet.photoLocalURL = URL(string: urlString)
                    
                    // Clean up local file
                    try? FileManager.default.removeItem(at: localURL)
                }
            }
            
            let dto = finalPet.toDTO(ownerId: ownerId)
            try await SupabaseManager.shared.client
                .from("pets")
                .insert(dto)
                .execute()
            
            return true
        } catch {
            print("Sync failed for pet \(pet.id): \(error)")
            return false
        }
    }
}
