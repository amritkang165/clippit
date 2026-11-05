// Purpose: Verify persistence, ordering, and consecutive duplicate handling in a temporary database.
import XCTest
@testable import Clippit

final class ClipStoreTests: XCTestCase {
    func testPersistenceAndConsecutiveDuplicates() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.sqlite3")
        let store = try ClipStore(databaseURL: url)
        XCTAssertTrue(try store.save("first"))
        XCTAssertFalse(try store.save("first"))
        XCTAssertTrue(try store.save("second"))
        XCTAssertTrue(try store.save("first"))
        XCTAssertEqual(store.items.map(\.content), ["first", "second", "first"])
        let reopened = try ClipStore(databaseURL: url)
        XCTAssertEqual(reopened.items, store.items)
        XCTAssertFalse(try reopened.save("first"))
    }
}
