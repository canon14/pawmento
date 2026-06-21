import Foundation
import SwiftUI
import Combine
import Supabase

struct ArchivePetDTO: Codable {
    let is_active: Bool
}

class PetStore: ObservableObject {
    static let fallbackPetName = "your pet"
    @Published var pets: [Pet] = []
    @Published var activePet: Pet? = nil
    
    @Published var isFetching = false
    @Published var fetchError: String? = nil
    
    init() { }
    
    @MainActor
    func fetchPets() async {
        isFetching = true
        fetchError = nil
        do {
            guard let ownerId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                isFetching = false
                return
            }
            
            let dtos: [PetDTO] = try await SupabaseManager.shared.client
                .from("pets")
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            let fetchedPets = dtos.map { $0.toPet() }.filter { $0.isActive }
            self.pets = fetchedPets
            
            if activePet == nil || !fetchedPets.contains(where: { $0.id == activePet?.id }) {
                self.activePet = fetchedPets.first
            }
        } catch {
            print("Failed to fetch pets: \(error)")
            fetchError = error.localizedDescription
        }
        isFetching = false
    }
    
    private func uploadPhoto(for pet: Pet, ownerId: UUID) async throws -> URL? {
        if let image = pet.photoImage {
            let path = "pets/\(ownerId.uuidString)/\(pet.id.uuidString).jpg"
            // Fix 2: uploadImage now returns the bucket-relative path.
            // We store the relative path; the DTO/display layer derives the full URL.
            let relativePath = try await StorageManager.shared.uploadImage(image, path: path)
            return StorageManager.shared.publicURL(forPath: relativePath)
        }
        return pet.photoLocalURL
    }
    
    @MainActor
    func addPet(_ pet: Pet, ownerId: UUID) async throws {
        var finalPet = pet
        
        do {
            finalPet.photoLocalURL = try await uploadPhoto(for: finalPet, ownerId: ownerId)
            
            let dto = finalPet.toDTO(ownerId: ownerId)
            let insertedDTO: PetDTO = try await SupabaseManager.shared.client
                .from("pets")
                .insert(dto)
                .select()
                .single()
                .execute()
                .value
            
            let insertedPet = insertedDTO.toPet()
            if !pets.contains(where: { $0.id == insertedPet.id }) {
                self.pets.append(insertedPet)
            }
            self.activePet = insertedPet
        } catch {
            print("Failed to insert pet: \(error)")
            throw error
        }
    }
    
    @MainActor
    func updatePet(_ pet: Pet, ownerId: UUID) async throws {
        var finalPet = pet
        
        do {
            finalPet.photoLocalURL = try await uploadPhoto(for: finalPet, ownerId: ownerId)
            
            let dto = finalPet.toDTO(ownerId: ownerId)
            try await SupabaseManager.shared.client
                .from("pets")
                .update(dto)
                .eq("id", value: pet.id.uuidString)
                .execute()
            
            // Update local after success
            if let index = pets.firstIndex(where: { $0.id == pet.id }) {
                pets[index] = finalPet
                if activePet?.id == pet.id {
                    activePet = finalPet
                }
            }
        } catch {
            print("Failed to update pet on server: \(error)")
            throw error
        }
    }
    
    @MainActor
    func archivePet(_ pet: Pet, ownerId: UUID) async throws {
        do {
            let dto = ArchivePetDTO(is_active: false)
            try await SupabaseManager.shared.client
                .from("pets")
                .update(dto)
                .eq("id", value: pet.id.uuidString)
                .execute()
            
            // Update local after success
            if let index = pets.firstIndex(where: { $0.id == pet.id }) {
                if activePet?.id == pet.id {
                    activePet = pets.first(where: { $0.isActive && $0.id != pet.id })
                }
            }
            pets.removeAll { $0.id == pet.id }
        } catch {
            print("Failed to archive pet on server: \(error)")
            throw error
        }
    }
    
    @MainActor
    func reset() {
        pets = []
        activePet = nil
        isFetching = false
        fetchError = nil
    }
}
