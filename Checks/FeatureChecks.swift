// Purpose: Check text transformations and history tools against isolated fixtures.
import Foundation
import AppKit
import SQLite

@MainActor func checkHistoryTools(in directory: URL) throws {
    let original = ClipItem(id: UUID(), timestamp: Date(), content: "  Hello\n WORLD ", isPinned: true)
    precondition(original.transformed(.trim)?.content == "Hello\n WORLD")
    precondition(original.transformed(.singleLine)?.content == "Hello WORLD")
    precondition(original.transformed(.uppercase)?.content == "  HELLO\n WORLD ")
    precondition(original.transformed(.lowercase)?.content == "  hello\n world ")
    precondition(original.content == "  Hello\n WORLD " && original.isPinned)
    precondition(TextTransform.singleLine.apply(to: "\t\n ").isEmpty)
    precondition(TextTransform.uppercase.apply(to: "straße") == "STRASSE")
    var image = original
    image.imagePath = "/unused/test.png"
    precondition(image.transformed(.trim) == nil)
    let store = try ClipStore(databaseURL: directory.appendingPathComponent("tools.sqlite3"))
    try store.save("alpha")
    let alpha = store.items[0]
    try store.save("beta")
    let beta = store.items[0]
    try store.save("gamma")
    // Equal timestamps must still sort deterministically by insertion order.
    let connection = try Connection(directory.appendingPathComponent("tools.sqlite3").path)
    try connection.run("UPDATE clips SET ts = 1000")
    let oldest = try store.search("", sort: .oldest)
    let newest = try store.search("", sort: .newest)
    precondition(oldest.map(\.content) == ["alpha", "beta", "gamma"])
    precondition(newest.map(\.content) == ["gamma", "beta", "alpha"])
    try store.setPinned(alpha.id, to: true)
    let pinnedFirst = try store.search("", sort: .pinnedFirst)
    precondition(pinnedFirst.map(\.content) == ["alpha", "gamma", "beta"])
    let filtered = try store.search("a", filter: .pinned, sort: .oldest)
    precondition(filtered.map(\.id) == [alpha.id])
    precondition(store.items.first?.content == "gamma")
    precondition(beta.content == "beta")
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let png = bitmap.representation(using: .png, properties: [:])!
    try store.saveImage(png)
    let retainedImage = store.items[0]
    try store.setPinned(retainedImage.id, to: true)
    try store.saveImage(png)
    let removedImage = store.items[0]
    // A failed SQL delete must leave both rows and owned image files intact.
    try connection.run("CREATE TRIGGER stop_clear BEFORE DELETE ON clips BEGIN SELECT RAISE(ABORT, 'test'); END")
    do { try store.clearUnpinned(); preconditionFailure("Expected trigger failure") }
    catch { }
    precondition(store.items.contains { $0.id == beta.id })
    precondition(FileManager.default.fileExists(atPath: removedImage.imagePath!))
    try connection.run("DROP TRIGGER stop_clear")
    try store.clearUnpinned()
    precondition(Set(store.items.map(\.id)) == Set([alpha.id, retainedImage.id]))
    precondition(FileManager.default.fileExists(atPath: retainedImage.imagePath!))
    precondition(!FileManager.default.fileExists(atPath: removedImage.imagePath!))
    let reopened = try ClipStore(databaseURL: directory.appendingPathComponent("tools.sqlite3"))
    precondition(reopened.items == store.items)
    try store.save("beta")
    precondition(store.items.first?.content == "beta")
    print("PASS: clear-unpinned rollback, pin preservation, image cleanup, restart, and recapture")
    print("PASS: deterministic SQLite sort modes with filters and timestamp ties")
    print("PASS: immutable text transformations, Unicode case conversion, and image exclusion")
}
