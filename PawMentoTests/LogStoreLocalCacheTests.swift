import XCTest
@testable import PawMento

final class LogStoreLocalCacheTests: XCTestCase {
    
    func testShouldShowLogInLocalCache_whenNoPetLoaded_acceptsLog() async {
        await MainActor.run {
            let store = LogStore()
            let log = LogEntry(petId: UUID(), category: .meal)
            XCTAssertTrue(store.shouldShowLogInLocalCache(log))
        }
    }
    
    func testMutateLocalCacheAfterSync_appendsWithoutDuplicate() async {
        await MainActor.run {
            let store = LogStore()
            let log = LogEntry(id: UUID(), petId: UUID(), category: .walk)
            
            store.mutateLocalCacheAfterSync(log)
            store.mutateLocalCacheAfterSync(log)
            
            XCTAssertEqual(store.logs.count, 1)
            XCTAssertEqual(store.logs.first?.id, log.id)
        }
    }
}
