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
}
