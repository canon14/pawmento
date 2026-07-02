import XCTest
@testable import PawMento

final class LogCategoryStoredValueTests: XCTestCase {
    
    func testFromStoredValue_lowercaseOtherSlug_mapsToOther() {
        XCTAssertEqual(LogCategory.fromStoredValue("other"), .other)
    }
    
    func testFromStoredValue_canonicalRawValue() {
        XCTAssertEqual(LogCategory.fromStoredValue("Other"), .other)
        XCTAssertEqual(LogCategory.fromStoredValue("Meal"), .meal)
    }
    
    func testFromStoredValue_caseInsensitiveDisplayName() {
        XCTAssertEqual(LogCategory.fromStoredValue("meal"), .meal)
        XCTAssertEqual(LogCategory.fromStoredValue("VET VISIT"), .vetVisit)
        XCTAssertEqual(LogCategory.fromStoredValue("energy level"), .energy)
    }
    
    func testCanonicalStoredValue_normalizesLegacyOther() {
        XCTAssertEqual(LogCategory.canonicalStoredValue(from: "other"), "Other")
    }
    
    func testDefaultReminderCategory_resolvesForNotificationTap() {
        // Schema default before F9 migration
        let categoryId = "other"
        let logCategory = LogCategory.fromStoredValue(categoryId)
        
        XCTAssertEqual(logCategory, .other)
        XCTAssertEqual(logCategory?.rawValue, "Other")
    }
}
