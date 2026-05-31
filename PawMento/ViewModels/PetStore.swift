import Foundation
import SwiftUI
import Combine

class PetStore: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var activePet: Pet? = nil
    
    init() {
        // Mock pet for development to ensure Quick Log has an active pet
        let mockPet = Pet(
            id: UUID(),
            name: "Buddy",
            species: .dog,
            breed: "Golden Retriever",
            birthday: DateComponents(year: 2021, month: 3),
            weightKg: 29.5,
            photoLocalURL: nil
        )
        pets = [mockPet]
        activePet = mockPet
    }
    
    func addPet(_ pet: Pet) {
        pets.append(pet)
        activePet = pet
    }
}
