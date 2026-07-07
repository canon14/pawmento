import XCTest
@testable import PawMento

@MainActor
final class CoachViewModelMessagePersistenceTests: XCTestCase {
    
    override func tearDown() {
        CoachMessagePersistence.insertHandler = nil
        super.tearDown()
    }
    
    func testSendMessage_onStreamError_persistsUserOnly() async {
        let ownerId = UUID()
        let pet = Pet(name: "Buddy", species: .dog)
        var persistedRoles: [String] = []
        
        CoachMessagePersistence.insertHandler = { dto in
            persistedRoles.append(dto.role)
        }
        
        let viewModel = CoachViewModel()
        viewModel.isPremium = true
        
        await viewModel.sendMessage("How much should Buddy eat?", pet: pet, ownerId: ownerId)
        
        XCTAssertEqual(persistedRoles, ["user"])
        XCTAssertEqual(viewModel.messages.filter { $0.role == .user }.count, 1)
        XCTAssertEqual(viewModel.messages.first { $0.role == .user }?.content, "How much should Buddy eat?")
    }
}
