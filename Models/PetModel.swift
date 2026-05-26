import Foundation
import UIKit

enum Species: Equatable {
    case dog
    case cat
    case rabbit
    case other(String)
}

struct Pet: Identifiable {
    let id: UUID
    var name: String
    var species: Species
    var breed: String?
    var birthday: DateComponents? // month + year only
    var weightKg: Double?
    var photoLocalURL: URL?
    var photoImage: UIImage?
    var createdAt: Date
    var isActive: Bool
    
    init(id: UUID = UUID(),
         name: String,
         species: Species,
         breed: String? = nil,
         birthday: DateComponents? = nil,
         weightKg: Double? = nil,
         photoLocalURL: URL? = nil,
         photoImage: UIImage? = nil,
         createdAt: Date = Date(),
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.species = species
        self.breed = breed
        self.birthday = birthday
        self.weightKg = weightKg
        self.photoLocalURL = photoLocalURL
        self.photoImage = photoImage
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
