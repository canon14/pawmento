import Foundation
import SwiftUI

struct AddPetResult {
    let pet: Pet
    let photoUploadWarning: String?
}

struct PetPhotoUpdateDTO: Codable {
    let photo_url: String?
}
