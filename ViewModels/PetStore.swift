import Foundation
import SwiftUI
import Combine

class PetStore: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var activePet: Pet? = nil
    
    func addPet(_ pet: Pet) {
        pets.append(pet)
        activePet = pet
    }
}
