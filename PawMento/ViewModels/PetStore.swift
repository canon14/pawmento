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
            ageYears: 3,
            ageMonths: 2,
            weightLbs: 65,
            photoURL: nil
        )
        pets = [mockPet]
        activePet = mockPet
    }
    
    func addPet(_ pet: Pet) {
        pets.append(pet)
        activePet = pet
    }
}
