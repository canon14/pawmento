import Foundation
import Combine
import UIKit
import Supabase
import Network

enum SyncTask: Codable {
    case createLog(LogEntry, UUID) // LogEntry and owner userId
    case updateLog(LogEntry, UUID)
    case deleteLog(UUID, UUID) // logId, ownerId
    case createPet(Pet, UUID) // Pet and owner userId
}

struct QueuedTask: Codable, Identifiable {
    let id: UUID
    let task: SyncTask
    var retryCount: Int
}

enum SyncResult {
    case success
    case transientError
    case permanentError
}

@MainActor
class OfflineSyncManager: ObservableObject {
    static let shared = OfflineSyncManager()
    private let queueKey = "pawmento_offline_sync_queue"
    
    @Published var isSyncing = false
    @Published var queuedTaskCount = 0
    
    private var queue: [QueuedTask] = []
    private let monitor = NWPathMonitor()
    
    private init() {
        loadQueue()
        
        // Start network monitor
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                Task { @MainActor in
                    self?.flushQueue()
                }
            }
        }
        monitor.start(queue: DispatchQueue.global())
        
        // Foreground observer
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flushQueue()
        }
    }
    
    func enqueueTask(_ task: SyncTask) {
        let queuedTask = QueuedTask(id: UUID(), task: task, retryCount: 0)
        queue.append(queuedTask)
        saveQueue()
        
        Task { @MainActor in
            self.flushQueue()
        }
    }
    
    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else { return }
        
        // Try decoding new format first
        if let savedQueue = try? JSONDecoder().decode([QueuedTask].self, from: data) {
            self.queue = savedQueue
            self.queuedTaskCount = savedQueue.count
            return
        }
        
        // Fallback to legacy format migration
        if let oldQueue = try? JSONDecoder().decode([SyncTask].self, from: data) {
            self.queue = oldQueue.map { QueuedTask(id: UUID(), task: $0, retryCount: 0) }
            self.queuedTaskCount = self.queue.count
            saveQueue() // Persist immediately in the new format
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
            
            // Iterate via index so we can incrementally remove/modify tasks in place
            var index = 0
            while index < queue.count {
                let queuedTask = queue[index]
                let result = await processTask(queuedTask.task)
                
                switch result {
                case .success:
                    queue.remove(at: index)
                    saveQueue() // Incremental save ensures progress isn't lost on crash
                    
                case .transientError:
                    print("Transient error encountered. Halting queue flush to preserve order.")
                    self.isSyncing = false
                    return
                    
                case .permanentError:
                    queue[index].retryCount += 1
                    if queue[index].retryCount >= 5 {
                        print("Deadlettering permanently failed task after 5 attempts: \(queuedTask.task)")
                        queue.remove(at: index)
                    } else {
                        print("Permanent error on task. Retry count: \(queue[index].retryCount)/5. Halting to preserve order.")
                        saveQueue() // Persist the incremented retry count
                        self.isSyncing = false
                        return
                    }
                    saveQueue()
                }
            }
            
            self.isSyncing = false
        }
    }
    
    private func processTask(_ task: SyncTask) async -> SyncResult {
        switch task {
        case .createLog(let log, let userId):
            return await syncLog(log, userId: userId)
        case .updateLog(let log, let userId):
            return await syncUpdateLog(log, userId: userId)
        case .deleteLog(let logId, let userId):
            return await syncDeleteLog(logId, userId: userId)
        case .createPet(let pet, let ownerId):
            return await syncPet(pet, ownerId: ownerId)
        }
    }
    
    private func categorizeError(_ error: Error) -> SyncResult {
        if let urlError = error as? URLError {
            return .transientError
        }
        // Assume anything else (like PostgRESTError or decoding failure) is permanent
        return .permanentError
    }
    
    private func syncLog(_ log: LogEntry, userId: UUID) async -> SyncResult {
        var finalLog = log
        do {
            if let localURL = log.photoLocalURL, localURL.isFileURL {
                if let data = try? Data(contentsOf: localURL), let image = UIImage(data: data) {
                    let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
                    let urlString = try await StorageManager.shared.uploadImage(image, path: path)
                    finalLog.photoLocalURL = URL(string: urlString)
                }
            }
            
            let dto = finalLog.toDTO(userId: userId)
            try await SupabaseManager.shared.client
                .from("logs")
                .upsert(dto) // Upsert provides idempotency
                .execute()
            
            // Cleanup local file ONLY after the entire DB insert is successful
            if let localURL = log.photoLocalURL, localURL.isFileURL {
                try? FileManager.default.removeItem(at: localURL)
            }
            
            return .success
        } catch {
            print("Sync failed for log \(log.id): \(error)")
            return categorizeError(error)
        }
    }
    
    private func syncUpdateLog(_ log: LogEntry, userId: UUID) async -> SyncResult {
        var finalLog = log
        do {
            if let localURL = log.photoLocalURL, localURL.isFileURL {
                if let data = try? Data(contentsOf: localURL), let image = UIImage(data: data) {
                    let path = "logs/\(userId.uuidString)/\(log.id.uuidString).jpg"
                    let urlString = try await StorageManager.shared.uploadImage(image, path: path)
                    finalLog.photoLocalURL = URL(string: urlString)
                }
            }
            
            let dto = finalLog.toDTO(userId: userId)
            try await SupabaseManager.shared.client
                .from("logs")
                .update(dto)
                .eq("id", value: log.id.uuidString)
                .execute()
            
            if let localURL = log.photoLocalURL, localURL.isFileURL {
                try? FileManager.default.removeItem(at: localURL)
            }
            
            return .success
        } catch {
            print("Update Sync failed for log \(log.id): \(error)")
            return categorizeError(error)
        }
    }
    
    private func syncDeleteLog(_ logId: UUID, userId: UUID) async -> SyncResult {
        do {
            try await SupabaseManager.shared.client
                .from("logs")
                .delete()
                .eq("id", value: logId.uuidString)
                .execute()
            
            return .success
        } catch {
            print("Delete Sync failed for log \(logId): \(error)")
            return categorizeError(error)
        }
    }
    
    private func syncPet(_ pet: Pet, ownerId: UUID) async -> SyncResult {
        var finalPet = pet
        do {
            if let localURL = pet.photoLocalURL, localURL.isFileURL {
                if let data = try? Data(contentsOf: localURL), let image = UIImage(data: data) {
                    let path = "pets/\(ownerId.uuidString)/\(pet.id.uuidString).jpg"
                    let urlString = try await StorageManager.shared.uploadImage(image, path: path)
                    finalPet.photoLocalURL = URL(string: urlString)
                }
            }
            
            let dto = finalPet.toDTO(ownerId: ownerId)
            try await SupabaseManager.shared.client
                .from("pets")
                .upsert(dto) // Upsert provides idempotency
                .execute()
            
            if let localURL = pet.photoLocalURL, localURL.isFileURL {
                try? FileManager.default.removeItem(at: localURL)
            }
            
            return .success
        } catch {
            print("Sync failed for pet \(pet.id): \(error)")
            return categorizeError(error)
        }
    }
}
