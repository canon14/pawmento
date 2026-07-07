import XCTest
@testable import PawMento

@MainActor
final class CoachViewModelSendGuardTests: XCTestCase {
    
    func testSendMessage_whileAlreadySending_isIgnored() async {
        let viewModel = CoachViewModel()
        viewModel.isPremium = true
        
        let first = Task {
            await viewModel.sendMessage("First question", pet: nil, ownerId: nil)
        }
        
        await Task.yield()
        XCTAssertTrue(viewModel.isSending)
        
        let userMessagesBefore = viewModel.messages.filter { $0.role == .user }.count
        XCTAssertEqual(userMessagesBefore, 1)
        
        await viewModel.sendMessage("Second question", pet: nil, ownerId: nil)
        
        XCTAssertEqual(
            viewModel.messages.filter { $0.role == .user }.count,
            userMessagesBefore
        )
        
        _ = await first.result
    }
}
