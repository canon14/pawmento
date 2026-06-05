import Foundation
import SwiftUI
import Combine
import Supabase

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
        var finalPet = pet
        
        do {
            // Upload photo if exists
            if let image = pet.photoImage {
                let path = "pets/\(ownerId.uuidString)/\(pet.id.uuidString).jpg"
                let urlString = try await StorageManager.shared.uploadImage(image, path: path)
                finalPet.photoLocalURL = URL(string: urlString)
            }
            
            let dto = finalPet.toDTO(ownerId: ownerId)
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
            var offlinePet = finalPet
            if let image = pet.photoImage,
               let localURL = StorageManager.shared.saveImageToDisk(image, fileName: "\(offlinePet.id.uuidString).jpg") {
                offlinePet.photoLocalURL = localURL
            }
            
            self.pets.append(offlinePet)
            self.activePet = offlinePet
            
            // Queue for later
            OfflineSyncManager.shared.enqueueTask(.createPet(offlinePet, ownerId))
        }
    }
    
    @MainActor
    func updatePet(_ pet: Pet, ownerId: UUID) async {
        // Update local first
        if let index = pets.firstIndex(where: { $0.id == pet.id }) {
            pets[index] = pet
            if activePet?.id == pet.id {
                activePet = pet
            }
        }
        
        do {
            let dto = pet.toDTO(ownerId: ownerId)
            try await SupabaseManager.shared.client
                .from("pets")
                .update(dto)
                .eq("id", value: pet.id.uuidString)
                .execute()
        } catch {
            print("Failed to update pet on server: \(error)")
        }
    }
    
    @MainActor
    func archivePet(_ pet: Pet, ownerId: UUID) async {
        if let index = pets.firstIndex(where: { $0.id == pet.id }) {
            pets[index].isActive = false
            
            // Switch to next active pet
            if activePet?.id == pet.id {
                activePet = pets.first(where: { $0.isActive && $0.id != pet.id })
            }
        }
        
        do {
            try await SupabaseManager.shared.client
                .from("pets")
                .update(["is_active": false])
                .eq("id", value: pet.id.uuidString)
                .execute()
        } catch {
            print("Failed to archive pet on server: \(error)")
        }
    }
}
