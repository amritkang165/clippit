// Purpose: Regress retained-history deduplication, snippet migration, copy feedback and shortcut replacement.
import XCTest
import AppKit
import SQLite
@testable import Clippit

final class RequestedIssuesTests: XCTestCase {
    private func database() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("test.sqlite3")
    }

    func testImmediatelyPrunedCopyCanBeCapturedAfterIncreasingCapacity() throws {
        let url = try database()
        let store = try ClipStore(databaseURL: url)
        try store.enforceLimit(1)
        try store.save("pinned")
        try store.setPinned(store.items[0].id, to: true)
        XCTAssertFalse(try store.save("wanted"))
        XCTAssertEqual(store.items.map(\.content), ["pinned"])
        try store.enforceLimit(2)
        XCTAssertTrue(try store.save("wanted"))
        XCTAssertFalse(try store.save("wanted"))
        XCTAssertFalse(try ClipStore(databaseURL: url).save("wanted"))
    }

    func testImmediatelyPrunedCopyCanBeCapturedAfterUnpinning() throws {
        let store = try ClipStore(databaseURL: database())
        try store.enforceLimit(1)
        try store.save("pinned")
        let pin = store.items[0].id
        try store.setPinned(pin, to: true)
        XCTAssertFalse(try store.save("wanted"))
        try store.setPinned(pin, to: false)
        XCTAssertTrue(try store.save("wanted"))
        XCTAssertEqual(store.items.map(\.content), ["wanted"])
    }

    func testLegacyMigrationAndSnippetLifecycle() throws {
        let url = try database()
        let legacy = try Connection(url.path)
        try legacy.run("CREATE TABLE clips (id TEXT PRIMARY KEY, ts DOUBLE NOT NULL, content TEXT NOT NULL, pinned INTEGER NOT NULL DEFAULT 0)")
        let oldID = UUID()
        try legacy.run("INSERT INTO clips VALUES (?, ?, ?, ?)", oldID.uuidString, 1.0, "old history", 1)
        let store = try ClipStore(databaseURL: url)
        XCTAssertEqual(store.items[0].id, oldID)
        let id = try store.saveSnippet(title: "  Reply 👋  ", text: "café\nhello 世界")
        XCTAssertEqual(try store.search("Reply").map(\.id), [id])
        XCTAssertEqual(try store.search("世界", filter: .snippets).map(\.id), [id])
        try store.saveSnippet(title: "100%_literal", text: "updated", editing: id)
        XCTAssertEqual(try store.search("%_").map(\.id), [id])
        XCTAssertEqual(try ClipStore(databaseURL: url).search("updated", filter: .snippets).map(\.id), [id])
        try store.enforceLimit(1)
        XCTAssertFalse(try store.save("pruned"))
        try store.clearUnpinned()
        XCTAssertEqual(store.items.count, 2)
        try store.clearAll()
        XCTAssertEqual(store.items.map(\.id), [id])
        let exported = try TextHistoryExport.encode(store.items)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        XCTAssertEqual(json["formatVersion"] as? Int, 2)
        let entry = try XCTUnwrap((json["clips"] as? [[String: Any]])?.first)
        XCTAssertEqual(entry["snippetTitle"] as? String, "100%_literal")
        XCTAssertEqual(entry["content"] as? String, "updated")
        try store.delete(id)
        XCTAssertTrue(try ClipStore(databaseURL: url).items.isEmpty)
        XCTAssertThrowsError(try store.saveSnippet(title: "lost", text: "content", editing: id))
        XCTAssertThrowsError(try store.saveSnippet(title: " ", text: "content"))
        XCTAssertThrowsError(try store.saveSnippet(title: "name", text: "\n"))
    }

    func testSnippetsDoNotConsumeCapacityOrChangeDuplicateTracking() throws {
        let store = try ClipStore(databaseURL: database())
        try store.enforceLimit(1)
        try store.save("history")
        let id = try store.saveSnippet(title: "History", text: "history")
        XCTAssertFalse(try store.save("history"))
        XCTAssertTrue(try store.save("next"))
        XCTAssertEqual(store.items.count, 2)
        XCTAssertTrue(store.items.contains { $0.id == id })
        XCTAssertEqual(try store.search("", filter: .snippets).count, 1)
    }

    @MainActor
    func testShortcutPersistenceReplacementAndFailure() async throws {
        let suite = "ClippitShortcutTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        var registrations = 0
        var released = 0
        var shouldFail = false
        var keyAction: (() -> Void)?
        var opened = 0
        let controller = HistoryShortcutController(register: { _, action in
            if shouldFail { throw ShortcutError.unavailable(-1) }
            registrations += 1
            keyAction = action
            return TestRegistration { released += 1 }
        }, action: { opened += 1 })
        settings.onShortcutChange = { try controller.replace(with: $0) }
        try controller.replace(with: settings.historyShortcut)
        let custom = HistoryShortcut(keyCode: 11, modifiers: NSEvent.ModifierFlags([.control, .option]).rawValue)
        try settings.setHistoryShortcut(custom)
        XCTAssertEqual(registrations, 2)
        XCTAssertEqual(released, 1)
        keyAction?()
        XCTAssertEqual(opened, 1)
        XCTAssertEqual(SettingsStore(defaults: defaults).historyShortcut, custom)
        shouldFail = true
        XCTAssertThrowsError(try settings.setHistoryShortcut(.default))
        XCTAssertEqual(settings.historyShortcut, custom)
        XCTAssertEqual(controller.current, custom)
        XCTAssertEqual(released, 1)
        XCTAssertThrowsError(try settings.setHistoryShortcut(HistoryShortcut(keyCode: 9, modifiers: 0)))
        shouldFail = false
        try settings.setHistoryShortcut(.default)
        XCTAssertEqual(SettingsStore(defaults: defaults).historyShortcut, .default)
        XCTAssertEqual(released, 2)
        defaults.set(Data("invalid".utf8), forKey: "historyShortcut")
        XCTAssertEqual(SettingsStore(defaults: defaults).historyShortcut, .default)
    }

    @MainActor
    func testCopyFeedbackRequiresSuccessAndResetsDuration() async throws {
        var announced = 0
        let feedback = CopyFeedback(duration: 100_000_000, announce: { announced += 1 })
        feedback.copy { false }
        XCTAssertFalse(feedback.isVisible)
        XCTAssertEqual(announced, 0)
        feedback.copy { true }
        XCTAssertTrue(feedback.isVisible)
        try await Task.sleep(nanoseconds: 60_000_000)
        feedback.copy { true }
        try await Task.sleep(nanoseconds: 60_000_000)
        XCTAssertTrue(feedback.isVisible)
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(feedback.isVisible)
        XCTAssertEqual(announced, 2)
        feedback.copy { true }
        feedback.copy {
            XCTAssertFalse(feedback.isVisible, "A previous success must clear before attempting another copy")
            return false
        }
        XCTAssertFalse(feedback.isVisible)
        XCTAssertEqual(announced, 3)
    }

    func testOCRFallbackAndFailureContract() throws {
        var attempts: [ImageTextRecognizer.Attempt] = []
        let text = try ImageTextRecognizer.withFallback(revision: 3, supported: IndexSet([1, 2, 3])) { attempt in
            attempts.append(attempt)
            if attempt.revision == 3 { throw CocoaError(.coderInvalidValue) }
            return "recognized"
        }
        XCTAssertEqual(text, "recognized")
        XCTAssertEqual(attempts, [.init(revision: 3, cpu: false), .init(revision: 3, cpu: true), .init(revision: 2, cpu: true)])
        XCTAssertThrowsError(try ImageTextRecognizer.withFallback { _ in throw CocoaError(.coderInvalidValue) }) {
            guard case ImageTextRecognizer.RecognitionError.unavailable = $0 else { return XCTFail("Wrong error: \($0)") }
        }
        var calls = 0
        XCTAssertThrowsError(try ImageTextRecognizer.withFallback { _ in calls += 1; throw CancellationError() }) {
            XCTAssertTrue($0 is CancellationError)
        }
        XCTAssertEqual(calls, 1)
    }
}

private final class TestRegistration: ShortcutRegistration {
    let release: () -> Void
    init(_ release: @escaping () -> Void) { self.release = release }
    deinit { release() }
}
