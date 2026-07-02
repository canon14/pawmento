import Foundation
import Supabase

struct PetDTO: Codable, Identifiable {
    let id: UUID
    let owner_id: UUID
    let name: String
    let species: String
    let breed: String?
    let birthday: String? // "YYYY-MM-DD"
    let weight_kg: Double?
    let photo_url: String?
    let is_active: Bool
    let created_at: Date
    
    func toPet() -> Pet {
        var dateComponents: DateComponents? = nil
        if let bdayStr = birthday {
            let parts = bdayStr.split(separator: "-")
            if parts.count >= 2, let year = Int(parts[0]), let month = Int(parts[1]) {
                dateComponents = DateComponents(year: year, month: month)
            }
        }
        
        let petSpecies: Species
        switch species.lowercased() {
        case "dog": petSpecies = .dog
        case "cat": petSpecies = .cat
        case "rabbit": petSpecies = .rabbit
        default: petSpecies = .other(species)
        }
        
        return Pet(
            id: id,
            name: name,
            species: petSpecies,
            breed: breed,
            birthday: dateComponents,
            weightKg: weight_kg,
            // Fix 2: photo_url stores a bucket-relative path; resolve to full URL for display.
            // publicURL(forPath:) also handles legacy full URLs via passthrough.
            photoLocalURL: photo_url.flatMap { StorageManager.shared.publicURL(forPath: $0) },
            photoImage: nil,
            createdAt: created_at,
            isActive: is_active
        )
    }
}

extension Pet {
    func toDTO(ownerId: UUID) -> PetDTO {
        var bdayStr: String? = nil
        if let bday = birthday, let year = bday.year, let month = bday.month {
            bdayStr = String(format: "%04d-%02d-01", year, month)
        }
        
        let speciesStr: String
        switch species {
        case .dog: speciesStr = "Dog"
        case .cat: speciesStr = "Cat"
        case .rabbit: speciesStr = "Rabbit"
        case .other(let name): speciesStr = name
        }
        
        return PetDTO(
            id: id,
            owner_id: ownerId,
            name: name,
            species: speciesStr,
            breed: breed,
            birthday: bdayStr,
            weight_kg: weightKg,
            photo_url: StorageManager.shared.relativeStoragePath(from: photoLocalURL),
            is_active: isActive,
            created_at: createdAt
        )
    }
}
