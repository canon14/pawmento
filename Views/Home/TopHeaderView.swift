import SwiftUI

struct TopHeaderView: View {
    @EnvironmentObject var petStore: PetStore
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                if let pet = petStore.activePet, let image = pet.photoImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                } else {
                    let emoji: String = {
                        guard let pet = petStore.activePet else { return "🐾" }
                        switch pet.species {
                        case .dog: return "🐶"
                        case .cat: return "🐱"
                        case .rabbit: return "🐰"
                        case .other: return "🐾"
                        }
                    }()
                    
                    Circle()
                        .fill(Color.primaryContainer)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(emoji)
                                .font(.system(size: 20))
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Good morning, Jordan ☀️")
                        .font(.headlineSM)
                        .foregroundColor(.primary)
                        .tracking(-0.5) // tracking-tight
                    
                    Text("Tuesday, May 26")
                        .font(.labelMD)
                        .foregroundColor(.onSurfaceVariant)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Action for notifications
            }) {
                Image(systemName: "bell.fill") // SF Symbol as stand-in for Material icon
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.surfaceContainer)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.background)
    }
}

#Preview {
    TopHeaderView()
}
