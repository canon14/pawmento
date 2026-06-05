import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var loadedImage: Image?
    
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        if let image = loadedImage {
            content(image)
        } else {
            placeholder()
                .task {
                    await loadImage()
                }
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        // 1. Check Cache
        if let cachedUIImage = ImageCache.shared.image(for: url) {
            loadedImage = Image(uiImage: cachedUIImage)
            return
        }
        
        // 2. Fetch from Network
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedUIImage = UIImage(data: data) {
                // 3. Save to Cache
                ImageCache.shared.insert(downloadedUIImage, for: url)
                // 4. Update UI
                loadedImage = Image(uiImage: downloadedUIImage)
            }
        } catch {
            print("Failed to load image from \(url): \(error)")
        }
    }
}
