import SwiftUI
import PhotosUI

struct PetPhotoWellView: View {
    @Binding var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 8) {
            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                ZStack {
                    Circle()
                        .fill(Color.cream)
                        .frame(width: 96, height: 96)
                    
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                        
                        // Edit indicator
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 24, height: 24)
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 32, y: 32)
                        
                    } else {
                        Circle()
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                            )
                            .foregroundColor(Color.primary)
                            .frame(width: 96, height: 96)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color.primary)
                    }
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            
            if selectedImage == nil {
                Text("Tap to add a photo")
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .foregroundColor(.tertiaryText)
            }
        }
    }
}
