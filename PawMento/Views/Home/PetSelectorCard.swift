import SwiftUI

struct PetSelectorCard: View {
    @EnvironmentObject var petStore: PetStore
    var onAddPet: () -> Void = {}
    @State private var showPetSwitcher = false
    
    var petAgeString: String? {
        guard let pet = petStore.activePet,
              let bday = pet.birthday,
              let bdayDate = Calendar.current.date(from: bday) else { return nil }
        let diff = Calendar.current.dateComponents([.year, .month], from: bdayDate, to: Date())
        let years = diff.year ?? 0
        let months = diff.month ?? 0
        if years <= 0 && months <= 0 { return nil }
        if years < 1 { return "\(months) mo" }
        if months == 0 { return "\(years)y" }
        return "\(years)y \(months)m"
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 20) {
                // Pet Avatar
                let avatarGradient = LinearGradient(colors: [Color.primary, Color.primary.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                
                Group {
                    if let pet = petStore.activePet, let image = pet.photoImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let pet = petStore.activePet, let photoURL = pet.photoLocalURL {
                        CachedAsyncImage(url: photoURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Color.surfaceContainerHigh
                                ProgressView()
                            }
                        }
                    } else {
                        ZStack {
                            Color.surfaceContainerHigh
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.primary.opacity(0.6))
                        }
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(avatarGradient, lineWidth: 2)
                )
                .shadow(color: Color.primary.opacity(0.2), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(petStore.activePet?.name ?? "No Pet")
                        .font(.headlineSM)
                        .fontWeight(.bold)
                        .foregroundColor(.onSurface)
                    
                    let breedString = petStore.activePet?.breed ?? "Mixed Breed"
                    HStack(spacing: 4) {
                        Text(breedString)
                            .foregroundColor(.onSurfaceVariant)
                        if let ageStr = petAgeString {
                            Text("•")
                                .foregroundColor(.onSurfaceVariant.opacity(0.5))
                            Text(ageStr)
                                .foregroundColor(.onSurfaceVariant)
                        }
                    }
                    .font(.labelMD)
                }
            }
            .background(Color.surfaceContainerLowest.opacity(0.01))
            .onTapGesture {
                if petStore.pets.count > 1 {
                    showPetSwitcher = true
                }
            }
            
            Spacer()
            
            Button(action: onAddPet) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color.primaryContainer.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(SquishyCardStyle())
        }
        .padding(20)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(AppRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.surfaceContainerLow, lineWidth: 1)
        )
        .warmShadow()
        .confirmationDialog("Switch Pet", isPresented: $showPetSwitcher, titleVisibility: .visible) {
            ForEach(petStore.pets) { pet in
                Button(pet.id == petStore.activePet?.id ? "\(pet.name) ✓" : pet.name) {
                    petStore.activePet = pet
                }
            }
        }
    }
}

#Preview {
    PetSelectorCard()
        .padding()
        .background(Color.background)
}
