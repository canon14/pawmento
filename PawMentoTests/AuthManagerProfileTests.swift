import XCTest
@testable import PawMento

final class AuthManagerProfileTests: XCTestCase {
    
    func testResolveDisplayName_prefersStoredProfileName() {
        let name = AuthManager.resolveDisplayName(
            storedName: "Max Gozali",
            email: "handle123@example.com"
        )
        XCTAssertEqual(name, "Max Gozali")
    }
    
    func testResolveDisplayName_fallsBackToEmailLocalPart() {
        let name = AuthManager.resolveDisplayName(
            storedName: nil,
            email: "max.gozali@example.com"
        )
        XCTAssertEqual(name, "Max Gozali")
    }
    
    func testResolveDisplayName_ignoresEmptyStoredName() {
        let name = AuthManager.resolveDisplayName(
            storedName: "   ",
            email: "max@example.com"
        )
        XCTAssertEqual(name, "Max")
    }
}
