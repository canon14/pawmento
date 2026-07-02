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
    
    func testResolvingStoredLogType_knownValue_normalizes() {
        XCTAssertEqual(
            LogCategory.resolvingStoredLogType("meal", context: "test"),
            .meal
        )
    }
    
    func testResolvingStoredLogType_unrecognized_mapsToUnknown() {
        XCTAssertEqual(
            LogCategory.resolvingStoredLogType("LegacyCorruptType", context: "test"),
            .unknown
        )
    }
    
    func testSelectableCategories_excludesUnknown() {
        XCTAssertFalse(LogCategory.selectableCategories.contains(.unknown))
    }
    
    func testLogDTO_unknownLogType_mapsToUnknownCategory() {
        let dto = LogDTO(
            id: UUID(),
            pet_id: UUID(),
            log_type: "LegacyCorruptType",
            title: "Legacy Log",
            description: nil,
            timestamp: Date(),
            created_at: Date(),
            created_by: UUID(),
            photo_url: nil,
            severity: nil,
            source_key: nil
        )
        
        XCTAssertEqual(dto.toLogEntry().category, .unknown)
    }
}
