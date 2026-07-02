import XCTest
@testable import PawMento

final class StorageManagerPathTests: XCTestCase {
    
    private let storage = StorageManager.shared
    private let sampleRelativePath = "abc123/pets/def456.jpg"
    private let samplePublicURL =
        "https://example.supabase.co/storage/v1/object/public/pawmento-media/abc123/pets/def456.jpg"
    
    func testRelativeStoragePath_keepsRelativePath() {
        XCTAssertEqual(
            storage.relativeStoragePath(from: sampleRelativePath),
            sampleRelativePath
        )
    }
    
    func testRelativeStoragePath_stripsLeadingSlashes() {
        XCTAssertEqual(
            storage.relativeStoragePath(from: "/abc123/pets/def456.jpg"),
            sampleRelativePath
        )
    }
    
    func testRelativeStoragePath_extractsFromPublicURL() {
        XCTAssertEqual(
            storage.relativeStoragePath(from: samplePublicURL),
            sampleRelativePath
        )
    }
    
    func testRelativeStoragePath_stripsQueryFromPublicURL() {
        let urlWithQuery = samplePublicURL + "?token=abc"
        XCTAssertEqual(
            storage.relativeStoragePath(from: urlWithQuery),
            sampleRelativePath
        )
    }
    
    func testRelativeStoragePath_fromDisplayURL() {
        let url = URL(string: samplePublicURL)!
        XCTAssertEqual(
            storage.relativeStoragePath(from: url),
            sampleRelativePath
        )
    }
    
    func testRelativeStoragePath_nilForEmpty() {
        XCTAssertNil(storage.relativeStoragePath(from: ""))
        XCTAssertNil(storage.relativeStoragePath(from: "   "))
        XCTAssertNil(storage.relativeStoragePath(from: nil as String?))
        XCTAssertNil(storage.relativeStoragePath(from: nil as URL?))
    }
}
