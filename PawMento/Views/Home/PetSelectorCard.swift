import SwiftUI

struct PetSelectorCard: View {
    @EnvironmentObject var petStore: PetStore
    var onAddPet: () -> Void = {}
    
    var petAgeString: String {
        guard let pet = petStore.activePet, let bday = pet.birthday, let year = bday.year else { return "" }
        let age = Calendar.current.component(.year, from: Date()) - year
        return age > 0 ? " · \(age) yrs" : ""
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 20) {
                // Pet Avatar
                if let pet = petStore.activePet, let image = pet.photoImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.primaryContainer, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                } else if let pet = petStore.activePet, let photoURL = pet.photoLocalURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.primaryContainer, lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    } placeholder: {
                        Circle()
                            .fill(Color.primaryContainer)
                            .frame(width: 56, height: 56)
                            .overlay(ProgressView())
                    }
                } else {
                    Circle()
                        .fill(Color.primaryContainer)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.primaryContainer, lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(petStore.activePet?.name ?? "No Pet")
                        .font(.headlineSM)
                        .foregroundColor(.onSurface)
                    
                    let breedString = petStore.activePet?.breed ?? "Mixed Breed"
                    Text("\(breedString)\(petAgeString)")
                        .font(.labelMD)
                        .foregroundColor(.onSurfaceVariant)
                }
            }
            
            Spacer()
            
            Button(action: onAddPet) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add another pet")
                        .font(.labelSM)
                }
                .foregroundColor(Color.secondary.opacity(0.7))
            }
        }
        .padding(20)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.surfaceContainerLow, lineWidth: 1)
        )
        .warmShadow()
    }
}

#Preview {
    PetSelectorCard()
        .padding()
        .background(Color.background)
}
