import Foundation
import UIKit
import Supabase

class StorageManager {
    static let shared = StorageManager()
    private let bucketName = "pawmento-media"
    
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
            .upload(path: path, file: data, options: fileOptions)
        
        // Fix 2: Return the bucket-relative path, NOT the full public URL.
        // The caller stores this in photo_url; the read side uses publicURL(forPath:) to display.
        return path
    }
    
    /// Derives the full public URL for a bucket-relative path.
    /// Handles backwards-compat: if the string is already a full URL, returns it as-is.
    func publicURL(forPath path: String) -> URL? {
        // Backwards-compat: if the stored value is already a full URL, pass through
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        return try? SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: path)
    }
    
    /// Deletes an image from Supabase Storage.
    /// Accepts a bucket-relative path. Also handles full URLs by stripping the bucket prefix.
    func deleteImage(path: String) async throws {
        var relativePath = path
        
        // If a full URL was passed, extract the bucket-relative portion
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            // Pattern: .../object/public/<bucketName>/<relativePath>
            let marker = "/object/public/\(bucketName)/"
            if let range = path.range(of: marker) {
                relativePath = String(path[range.upperBound...])
            }
        }
        
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
