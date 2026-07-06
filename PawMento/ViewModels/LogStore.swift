import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
class LogStore: ObservableObject {
    static let shared = LogStore()
    
    @Published var logs: [LogEntry] = []
    @Published var isFetching = false
    @Published var fetchError: String? = nil
    
    // Fix S1: Track which pet's logs are currently loaded so we don't
    // contaminate the visible list with logs from a different pet.
    private(set) var loadedPetId: UUID?
    
    // Fix S2: Latest-wins token to prevent stale fetch responses from
    // overwriting fresh data when the user rapidly switches pets.
    private var fetchRequestId: UUID?
    
    // Fix S8: Shared path builder so upload and delete paths can't drift.
    static func logPhotoPath(userId: UUID, logId: UUID) -> String {
        "\(userId.uuidString)/logs/\(logId.uuidString).jpg"
    }
    
    // MARK: - Save
    
    @MainActor
    func saveLog(_ log: LogEntry, userId: UUID) async throws {
        // 1. Upload photo if exists
        var finalLog = log
        if let image = log.photoImage {
            let path = Self.logPhotoPath(userId: userId, logId: log.id)
            let relativePath = try await StorageManager.shared.uploadImage(image, path: path)
            finalLog.photoLocalURL = StorageManager.shared.publicURL(forPath: relativePath)
            // Fix S3: Clear the in-memory image so subsequent updates don't re-upload
            finalLog.photoImage = nil
        }
        
        // 2. Sync to Supabase
        let dto = finalLog.toDTO(userId: userId)
        try await SupabaseManager.shared.client
            .from("logs")
            .insert(dto)
            .execute()
            
        finalLog.syncedAt = Date()
        
        // 3. Update in-memory cache when this log belongs to the visible pet.
        mutateLocalCacheAfterSync(finalLog)
        
        // 4. Remember last used category for this pet
        let key = "lastUsedCategory_\(log.petId.uuidString)"
        UserDefaults.standard.set(log.category.rawValue, forKey: key)
        
        // Fix I3: Invalidate insight cache so new logs surface on next Insights load
        await InsightEngine.shared.clearCache(for: finalLog.petId)
    }
    
    // MARK: - Update
    
    @MainActor
    func updateLog(_ log: LogEntry, userId: UUID) async throws {
        // 1. Upload photo if it's new/updated
        var finalLog = log
        if let image = log.photoImage {
            let path = Self.logPhotoPath(userId: userId, logId: log.id)
            let relativePath = try await StorageManager.shared.uploadImage(image, path: path)
            finalLog.photoLocalURL = StorageManager.shared.publicURL(forPath: relativePath)
            // Fix S3: Clear the in-memory image so subsequent updates don't re-upload
            finalLog.photoImage = nil
        }
        
        // 2. Sync to Supabase
        let dto = finalLog.toUpdateDTO()
        try await SupabaseManager.shared.client
            .from("logs")
            .update(dto)
            .eq("id", value: log.id.uuidString)
            .execute()
            
        finalLog.syncedAt = Date()
        
        // 3. Fix S1: Only mutate the local array if this log belongs to the
        // currently-loaded pet.
        if finalLog.petId == loadedPetId {
            if let index = logs.firstIndex(where: { $0.id == log.id }) {
                logs[index] = finalLog
                logs.sort(by: { $0.recordedAt > $1.recordedAt })
            }
        }
        
        // Fix I3: Invalidate insight cache so edits surface on next Insights load
        await InsightEngine.shared.clearCache(for: finalLog.petId)
    }
    
    // MARK: - Delete
    
    @MainActor
    func deleteLog(_ log: LogEntry, userId: UUID) async throws {
        // 1. Delete from Supabase
        try await SupabaseManager.shared.client
            .from("logs")
            .delete()
            .eq("id", value: log.id.uuidString)
            .execute()
            
        // 2. Fix S8: Clean up remote photo using the shared path builder
        if log.photoLocalURL != nil {
            let path = Self.logPhotoPath(userId: userId, logId: log.id)
            try? await StorageManager.shared.deleteImage(path: path)
        }
        
        // 3. Remove locally after success
        logs.removeAll { $0.id == log.id }
        
        // Fix I3: Invalidate insight cache so deletion surfaces on next Insights load
        await InsightEngine.shared.clearCache(for: log.petId)
    }
    
    // MARK: - Fetch
    
    @MainActor
    func fetchLogs(for petId: UUID) async {
        // Fix S2: Latest-wins guard — capture a token so stale responses are discarded.
        let requestId = UUID()
        fetchRequestId = requestId
        loadedPetId = petId
        
        isFetching = true
        fetchError = nil
        
        do {
            let dtos: [LogDTO] = try await SupabaseManager.shared.client
                .from("logs")
                .select()
                .eq("pet_id", value: petId.uuidString)
                .order("timestamp", ascending: false)
                .execute()
                .value
            
            // Fix S2: Only apply results if this is still the latest request
            guard fetchRequestId == requestId else { return }
            
            self.logs = dtos.map { $0.toLogEntry() }
        } catch {
            guard fetchRequestId == requestId else { return }
            print("Failed to fetch logs: \(error)")
            fetchError = error.localizedDescription
        }
        
        // Only clear isFetching if we're still the latest request
        if fetchRequestId == requestId {
            isFetching = false
        }
    }
    
    // MARK: - Helpers
    
    func shouldShowLogInLocalCache(_ log: LogEntry) -> Bool {
        if let loadedPetId {
            return log.petId == loadedPetId
        }
        // Before the first fetch, accept logs for a single pet so notification taps
        // and early writes still appear in the UI.
        return logs.isEmpty || logs.allSatisfy { $0.petId == log.petId }
    }
    
    func mutateLocalCacheAfterSync(_ log: LogEntry) {
        guard shouldShowLogInLocalCache(log) else { return }
        guard !logs.contains(where: { $0.id == log.id }) else { return }
        logs.append(log)
        logs.sort(by: { $0.recordedAt > $1.recordedAt })
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
        loadedPetId = nil
        fetchRequestId = nil
        isFetching = false
        fetchError = nil
    }
}
