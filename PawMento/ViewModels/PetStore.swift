import Foundation
import SwiftUI
import Combine

class PetStore: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var activePet: Pet? = nil
    
    init() {
        // Mock data removed. Pets will be fetched upon authentication.
    }
    
    @MainActor
    func fetchPets() async {
        do {
            let dtos: [PetDTO] = try await SupabaseManager.shared.client
                .from("pets")
                .select()
                .execute()
                .value
            
            self.pets = dtos.map { $0.toPet() }
            self.activePet = self.pets.first
        } catch {
            print("Failed to fetch pets: \(error)")
        }
    }
    
    @MainActor
    func addPet(_ pet: Pet, ownerId: UUID) async {
        do {
            let dto = pet.toDTO(ownerId: ownerId)
            let insertedDTO: PetDTO = try await SupabaseManager.shared.client
                .from("pets")
                .insert(dto)
                .select()
                .single()
                .execute()
                .value
            
            let insertedPet = insertedDTO.toPet()
            self.pets.append(insertedPet)
            self.activePet = insertedPet
        } catch {
            print("Failed to insert pet: \(error)")
            // Fallback for UI if offline/error
            self.pets.append(pet)
            self.activePet = pet
        }
    }
}
