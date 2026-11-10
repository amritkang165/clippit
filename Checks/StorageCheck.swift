// Purpose: Exercise real SQLite persistence in an isolated temporary directory.
import Foundation
import AppKit

@main struct StorageCheck {
    @MainActor static func main() async throws {
        let suite = CommandLine.arguments.dropFirst().first ?? "all"
        guard ["all", "core", "ocr"].contains(suite) else { fatalError("Unknown check suite") }
        if suite != "ocr" { try runSynchronousChecks() }
        if suite != "core" { try await checkImageTextRecognition() }
    }

    @MainActor static func runSynchronousChecks() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.sqlite3")
        let store = try ClipStore(databaseURL: url)
        let first = try store.save("first")
        let duplicate = try store.save("first")
        let second = try store.save("second")
        let repeated = try store.save("first")
        precondition(first && !duplicate && second && repeated)
        precondition(store.items.map(\.content) == ["first", "second", "first"])
        let reopened = try ClipStore(databaseURL: url)
        precondition(reopened.items == store.items)
        let restartDuplicate = try reopened.save("first")
        precondition(!restartDuplicate)
        try store.enforceLimit(2)
        precondition(store.items.map(\.content) == ["first", "second"])
        _ = try store.save("third")
        precondition(store.items.map(\.content) == ["third", "first"])
        let suite = "ClippitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        precondition(settings.maxItems == 500 && settings.ignorePasswords)
        settings.maxItems = 25
        settings.ignorePasswords = false
        let restored = SettingsStore(defaults: defaults)
        precondition(restored.maxItems == 25 && !restored.ignorePasswords)
        settings.maxItems = 0
        precondition(settings.maxItems == 1 && defaults.integer(forKey: "maxItems") == 1)
        let pinnedItem = store.items.last!
        try store.setPinned(pinnedItem.id, to: true)
        _ = try store.save("fourth")
        precondition(store.items.contains { $0.id == pinnedItem.id && $0.isPinned })
        let pinnedReopen = try ClipStore(databaseURL: url)
        precondition(pinnedReopen.items.contains { $0.id == pinnedItem.id && $0.isPinned })
        try store.enforceLimit(1)
        precondition(store.items.count == 1 && store.items[0].isPinned)
        try store.setPinned(pinnedItem.id, to: false)
        _ = try store.save("fifth")
        precondition(store.items.count == 1 && store.items[0].content == "fifth")
        precondition(HistoryView.relativeTime(Date(timeIntervalSince1970: 0), now: Date(timeIntervalSince1970: 120)) == "2m ago")
        precondition(ClipboardMonitor.isPasswordApp("com.agilebits.onepassword7"))
        precondition(ClipboardMonitor.isPasswordApp("com.apple.keychainaccess"))
        precondition(!ClipboardMonitor.isPasswordApp("com.apple.TextEdit"))

        // A private pasteboard keeps these checks away from the user's clipboard.
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        settings.ignorePasswords = false
        let monitor = ClipboardMonitor(settings: settings, pasteboard: pasteboard)
        var captured: [String] = []
        monitor.onText = { captured.append($0) }
        monitor.start()
        monitor.start() // Starting twice must not create duplicate timers.
        pasteboard.clearContents()
        pasteboard.setString("test text", forType: .string)
        RunLoop.main.run(until: Date().addingTimeInterval(0.65))
        precondition(captured == ["test text"])
        pasteboard.clearContents()
        pasteboard.setData(Data([0, 1, 2]), forType: .png)
        RunLoop.main.run(until: Date().addingTimeInterval(0.65))
        precondition(captured == ["test text"])
        settings.ignorePasswords = true
        pasteboard.clearContents()
        pasteboard.setString("secret test", forType: .string)
        pasteboard.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        RunLoop.main.run(until: Date().addingTimeInterval(0.65))
        precondition(captured == ["test text"])
        precondition(monitor.copyToClipboard("restored"))
        RunLoop.main.run(until: Date().addingTimeInterval(0.65))
        precondition(pasteboard.string(forType: .string) == "restored")
        precondition(captured == ["test text"])
        monitor.stop()
        try checkHistoryTools(in: directory)
        checkCaptureControls()
        try checkImages(in: directory, settings: settings)
        try checkSearch(in: directory)
        try checkSearchFocus(in: directory)
        try checkMenuAndClear(in: directory)
        try checkPolish(in: directory)
        try checkRequestedFeatures(in: directory)
        print("PASS: persistent pins, pin-safe pruning, unpinning, relative times")
        print("PASS: timer capture, non-text skip, confidential marker skip, restoration without recapture")
        print("PASS: settings defaults, persistence, clamping, and pruning")
        print("PASS: persistence, newest-first ordering, consecutive duplicates, restart duplicates")
    }
}
