import Foundation
import UIKit
import Supabase

class StorageManager {
    static let shared = StorageManager()
    private let bucketName = "pawmento-media"
    
    /// Supabase public-object URL segment: `.../object/public/<bucket>/`
    private var publicObjectMarker: String {
        "/object/public/\(bucketName)/"
    }
    
    // MARK: - Path ↔ URL conversion
    
    /// Normalizes a stored DB value or display URL into a bucket-relative object path.
    /// Use this before writing `photo_url` to the database.
    func relativeStoragePath(from storedValue: String?) -> String? {
        guard var value = storedValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        
        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            if let range = value.range(of: publicObjectMarker) {
                value = String(value[range.upperBound...])
            }
            if let queryIndex = value.firstIndex(of: "?") {
                value = String(value[..<queryIndex])
            }
            if let fragmentIndex = value.firstIndex(of: "#") {
                value = String(value[..<fragmentIndex])
            }
        }
        
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return value.isEmpty ? nil : value
    }
    
    /// Convenience for models that keep a display `URL` in memory.
    func relativeStoragePath(from displayURL: URL?) -> String? {
        guard let displayURL else { return nil }
        return relativeStoragePath(from: displayURL.absoluteString)
    }
    
    /// Resolves a bucket-relative path (or legacy full URL) to a public display URL.
    /// Always normalizes through `relativeStoragePath` so host/bucket changes don't break reads.
    func publicURL(forPath path: String) -> URL? {
        guard let relativePath = relativeStoragePath(from: path) else { return nil }
        return try? SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: relativePath)
    }
    
    // MARK: - Remote Storage (Supabase)
    
    /// Uploads an image to Supabase Storage and returns the **bucket-relative path**
    /// (e.g. "pets/uuid/uuid.jpg"). Callers should store this path in the DB;
    /// use `publicURL(forPath:)` to derive the display URL at read time.
    /// Fix 7: upsert=true so re-uploads to the same path succeed without conflict.
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.3) else {
            throw NSError(domain: "StorageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        // Fix 7: upsert: true prevents 409 conflicts on re-upload
        let fileOptions = FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)
        try await SupabaseManager.shared.client.storage
            .from(bucketName)
            .upload(path, data: data, options: fileOptions)
        
        // Fix 2: Return the bucket-relative path, NOT the full public URL.
        // The caller stores this in photo_url; the read side uses publicURL(forPath:) to display.
        return path
    }
    
    /// Deletes an image from Supabase Storage.
    /// Accepts a bucket-relative path or legacy full public URL.
    func deleteImage(path: String) async throws {
        guard let relativePath = relativeStoragePath(from: path) else { return }
        
        try await SupabaseManager.shared.client.storage
            .from(bucketName)
            .remove(paths: [relativePath])
    }
    
    // MARK: - Local / Offline Storage
    
    /// Saves an image to the local documents directory under "OfflineImages/".
    /// Fix 3: Returns ONLY the relative filename (e.g. "photo_abc.jpg"), not an absolute path.
    /// Use `urlForOfflineImage(fileName:)` or `loadImageFromDisk(fileName:)` to read it back.
    func saveImageToDisk(_ image: UIImage, fileName: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.5) else { return nil }
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Ensure "OfflineImages" folder exists
        let folderURL = directory.appendingPathComponent("OfflineImages")
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        let fileURL = folderURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save image to disk: \(error)")
            return nil
        }
    }
    
    /// Loads a previously saved offline image by filename.
    func loadImageFromDisk(fileName: String) -> UIImage? {
        let url = urlForOfflineImage(fileName: fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    /// Returns the absolute file URL for an offline image given its relative filename.
    func urlForOfflineImage(fileName: String) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("OfflineImages").appendingPathComponent(fileName)
    }
}
