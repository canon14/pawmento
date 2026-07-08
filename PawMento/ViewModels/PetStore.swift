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
        // Fix S6: Reentrancy guard — prevent overlapping fetches
        guard !isFetching else { return }
        
        isFetching = true
        fetchError = nil
        do {
            guard let ownerId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                isFetching = false
                return
            }
            
            // Fix S4: Filter is_active server-side to avoid transferring archived pets
            let dtos: [PetDTO] = try await SupabaseManager.shared.client
                .from("pets")
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .eq("is_active", value: true)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            let fetchedPets = dtos.map { $0.toPet() }
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
    
    // Shared path builder for pet photos (mirrors LogStore.logPhotoPath)
    static func petPhotoPath(ownerId: UUID, petId: UUID) -> String {
        "\(ownerId.uuidString)/pets/\(petId.uuidString).jpg"
    }
    
    private func uploadPhoto(for pet: Pet, ownerId: UUID) async throws -> URL? {
        if let image = pet.photoImage {
            let path = Self.petPhotoPath(ownerId: ownerId, petId: pet.id)
            let relativePath = try await StorageManager.shared.uploadImage(image, path: path)
            return StorageManager.shared.publicURL(forPath: relativePath)
        }
        return pet.photoLocalURL
    }
    
    @MainActor
    func addPet(_ pet: Pet, ownerId: UUID) async throws -> AddPetResult {
        try await UserBootstrap.ensure()
        
        var finalPet = pet
        let imageToUpload = finalPet.photoImage
        finalPet.photoImage = nil
        
        do {
            let dto = finalPet.toDTO(ownerId: ownerId)
            let insertedDTO: PetDTO = try await SupabaseManager.shared.client
                .from("pets")
                .insert(dto)
                .select()
                .single()
                .execute()
                .value
            
            var insertedPet = insertedDTO.toPet()
            var photoWarning: String?
            
            if let image = imageToUpload {
                do {
                    let path = Self.petPhotoPath(ownerId: ownerId, petId: insertedPet.id)
                    let relativePath = try await StorageManager.shared.uploadImage(image, path: path)
                    try await SupabaseManager.shared.client
                        .from("pets")
                        .update(PetPhotoUpdateDTO(photo_url: relativePath))
                        .eq("id", value: insertedPet.id.uuidString)
                        .execute()
                    insertedPet.photoLocalURL = StorageManager.shared.publicURL(forPath: relativePath)
                } catch {
                    print("Failed to upload pet photo: \(error)")
                    photoWarning = "Pet saved, but photo upload failed. You can add a photo later from the pet profile."
                }
            }
            
            insertedPet.photoImage = nil
            if !pets.contains(where: { $0.id == insertedPet.id }) {
                self.pets.append(insertedPet)
            }
            self.activePet = insertedPet
            return AddPetResult(pet: insertedPet, photoUploadWarning: photoWarning)
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
            // Fix S3: Clear in-memory image after upload to prevent re-uploads
            finalPet.photoImage = nil
            
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
    
    // Fix S5: Cleaned up dead code — removed unused `index` binding and
    // redundant isActive check. Compute activePet from remaining pets AFTER removal.
    @MainActor
    func archivePet(_ pet: Pet, ownerId: UUID) async throws {
        do {
            let dto = ArchivePetDTO(is_active: false)
            try await SupabaseManager.shared.client
                .from("pets")
                .update(dto)
                .eq("id", value: pet.id.uuidString)
                .execute()
            
            // Remove from local list first
            pets.removeAll { $0.id == pet.id }
            
            // Then pick new activePet from the remaining pets (nil if last pet archived)
            if activePet?.id == pet.id {
                activePet = pets.first
            }
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
