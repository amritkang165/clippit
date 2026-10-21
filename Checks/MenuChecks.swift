// Purpose: Verify recent-menu ordering, readable previews, and atomic clearing of clips and owned images.
import AppKit
import SQLite

func checkMenuAndClear(in directory: URL) throws {
    let folder = directory.appendingPathComponent("menu-checks", isDirectory: true)
    let url = folder.appendingPathComponent("clips.sqlite3")
    let store = try ClipStore(databaseURL: url)
    precondition(store.items.isEmpty && store.recentItems.isEmpty)
    for index in 0..<12 { try store.save("entry \(index)") }
    let oldest = store.items.last!
    try store.setPinned(oldest.id, to: true)
    precondition(store.items.count == 12)
    precondition(store.recentItems.map(\.content) == (2..<12).reversed().map { "entry \($0)" })

    func title(_ content: String) -> String {
        ClipItem(id: UUID(), timestamp: Date(), content: content, isPinned: false).menuTitle
    }
    precondition(title("a\nb\tc\r\nd") == "a b c d")
    precondition(title(" \n\t ") == "(Empty text)")
    precondition(title(String(repeating: "a", count: 40)) == String(repeating: "a", count: 40))
    precondition(title(String(repeating: "a", count: 41)) == String(repeating: "a", count: 39) + "…")
    let emojiTitle = title(String(repeating: "👨‍👩‍👧‍👦", count: 50))
    precondition(emojiTitle.count == 40 && emojiTitle.last == "…")

    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    bitmap.setColor(NSColor(deviceWhite: 0.5, alpha: 1), atX: 0, y: 0)
    try store.saveImage(bitmap.representation(using: .png, properties: [:])!)
    let image = store.items[0]
    try store.setPinned(image.id, to: true)
    precondition(store.recentItems.first?.id == image.id && store.recentItems.count == 10)
    precondition(image.menuTitle == "🖼 Image")
    let imagePath = image.imagePath!
    let unrelated = folder.appendingPathComponent("keep-me.png")
    try Data("unrelated local file".utf8).write(to: unrelated)

    // Simulate a failed clear and verify the database and image stay intact.
    let db = try Connection(url.path)
    try db.run("CREATE TRIGGER reject_clear BEFORE DELETE ON clips BEGIN SELECT RAISE(ABORT, 'test clear failure'); END")
    let before = store.items
    do {
        try store.clearAll()
        preconditionFailure("Injected DELETE failure must throw")
    } catch {
        precondition(store.items == before)
        let persisted = try store.search("")
        precondition(persisted == before && FileManager.default.fileExists(atPath: imagePath))
    }
    try db.run("DROP TRIGGER reject_clear")
    try store.clearAll()
    precondition(store.items.isEmpty && store.recentItems.isEmpty)
    precondition(!FileManager.default.fileExists(atPath: imagePath))
    precondition(FileManager.default.fileExists(atPath: unrelated.path))
    let reopened = try ClipStore(databaseURL: url)
    precondition(reopened.items.isEmpty)
    try store.clearAll() // Clearing an already-empty database remains safe.
    try store.save("copy after clear")
    try store.clearAll()
    let savedAgain = try store.save("copy after clear")
    precondition(savedAgain && store.items.count == 1)
    print("PASS: live count source, ten newest clips, text/image menu labels, 40-character Unicode truncation")
    print("PASS: clear-all rollback, pinned text/image deletion, image cleanup, unrelated-file preservation, restart and recopy")
}
