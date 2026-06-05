import Foundation
import UIKit
import Supabase

class StorageManager {
    static let shared = StorageManager()
    private let bucketName = "pawmento-media"
    
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        // High compression to keep app fast and storage cheap
        guard let data = image.jpegData(compressionQuality: 0.3) else {
            throw NSError(domain: "StorageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        // Upload to Supabase Storage
        let fileOptions = FileOptions(cacheControl: "3600", contentType: "image/jpeg")
        try await SupabaseManager.shared.client.storage
            .from(bucketName)
            .upload(path: path, file: data, options: fileOptions)
        
        // Get the public URL
        let publicURL = try SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
    
    func saveImageToDisk(_ image: UIImage, fileName: String) -> URL? {
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
            return fileURL
        } catch {
            print("Failed to save image to disk: \(error)")
            return nil
        }
    }
}
