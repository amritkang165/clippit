// Purpose: Verify schema migration, image files, thumbnails, clipboard round trips, and cleanup.
import AppKit
import SQLite

func checkImages(in directory: URL, settings: SettingsStore) throws {
    let legacyURL = directory.appendingPathComponent("legacy.sqlite3")
    let legacy = try Connection(legacyURL.path)
    try legacy.run("CREATE TABLE clips (id TEXT PRIMARY KEY, ts REAL, content TEXT, pinned INTEGER)")
    let legacyID = UUID().uuidString
    try legacy.run("INSERT INTO clips VALUES (?, ?, ?, ?)", legacyID, 1.0, "legacy text", 1)
    let migrated = try ClipStore(databaseURL: legacyURL)
    precondition(migrated.items.count == 1 && migrated.items[0].imagePath == nil && migrated.items[0].isPinned)
    let migratedAgain = try ClipStore(databaseURL: legacyURL)
    precondition(migratedAgain.items == migrated.items)

    let imageFolder = directory.appendingPathComponent("image-checks", isDirectory: true)
    let imageURL = imageFolder.appendingPathComponent("images.sqlite3")
    let store = try ClipStore(databaseURL: imageURL)
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 240, pixelsHigh: 120,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    for y in 0..<120 {
        for x in 0..<240 { bitmap.setColor(NSColor(deviceRed: 0.1, green: 0.4, blue: 0.9, alpha: 1), atX: x, y: y) }
    }
    let png = bitmap.representation(using: .png, properties: [:])!
    let tiff = bitmap.tiffRepresentation!
    _ = try store.save("same text")
    try store.saveImage(tiff)
    let item = store.items[0]
    let file = URL(fileURLWithPath: item.imagePath!)
    precondition(file.pathExtension == "png" && FileManager.default.fileExists(atPath: file.path))
    let decoded = NSBitmapImageRep(data: try Data(contentsOf: file))!
    precondition(decoded.pixelsWide == 240 && decoded.pixelsHigh == 120)
    let thumbnail = ClipImages.thumbnail(at: file.path)!
    precondition(thumbnail.size.width <= 80 && thumbnail.size.height <= 80)
    let repeatedText = try store.save("same text")
    precondition(repeatedText) // An intervening image breaks consecutive-text duplication.
    let reopened = try ClipStore(databaseURL: imageURL)
    precondition(reopened.items == store.items)
    do {
        try store.saveImage(Data([0, 1, 2]))
        preconditionFailure("Invalid image must fail")
    } catch { precondition(store.items.count == 3) }

    let board = NSPasteboard.withUniqueName()
    defer { board.releaseGlobally() }
    settings.ignorePasswords = false
    let monitor = ClipboardMonitor(settings: settings, pasteboard: board)
    var capturedImages = 0
    var capturedTexts = 0
    monitor.onImage = { _ in capturedImages += 1 }
    monitor.onText = { _ in capturedTexts += 1 }
    monitor.start()
    for type in [NSPasteboard.PasteboardType.png, .tiff] {
        board.clearContents()
        board.setData(type == .png ? png : tiff, forType: type)
        board.setString("fallback text", forType: .string)
        RunLoop.main.run(until: Date().addingTimeInterval(0.65))
    }
    precondition(capturedImages == 2 && capturedTexts == 0)
    settings.ignorePasswords = true
    board.clearContents()
    board.setData(png, forType: .png)
    board.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
    RunLoop.main.run(until: Date().addingTimeInterval(0.65))
    precondition(capturedImages == 2)
    let restored = try monitor.copyToClipboard(item)
    precondition(restored && board.data(forType: .png) != nil && board.data(forType: .tiff) != nil)
    RunLoop.main.run(until: Date().addingTimeInterval(0.65))
    precondition(capturedImages == 2)
    monitor.stop()

    try store.setPinned(item.id, to: true)
    try store.enforceLimit(1)
    precondition(store.items.count == 1 && FileManager.default.fileExists(atPath: file.path))
    try store.setPinned(item.id, to: false)
    _ = try store.save("prunes image")
    precondition(!FileManager.default.fileExists(atPath: file.path))
    monitor.copyToClipboard("keep existing clipboard")
    do {
        _ = try monitor.copyToClipboard(item)
        preconditionFailure("Missing image must fail")
    } catch { precondition(board.string(forType: .string) == "keep existing clipboard") }

    // A failed database insert must not leave a newly written image behind.
    let connection = try Connection(imageURL.path)
    try connection.run("CREATE TRIGGER reject_image BEFORE INSERT ON clips WHEN NEW.imagePath IS NOT NULL BEGIN SELECT RAISE(ABORT, 'test failure'); END")
    do {
        try store.saveImage(png)
        preconditionFailure("Injected database failure must throw")
    } catch {
        let files = try FileManager.default.contentsOfDirectory(at: imageFolder, includingPropertiesForKeys: nil)
        precondition(!files.contains { $0.pathExtension == "png" })
    }
    print("PASS: legacy migration, PNG/TIFF capture, image round trip, 40pt thumbnail source, invalid/missing images")
    print("PASS: image pins, pruning cleanup, failed-insert cleanup, confidential image skip, no image recapture")
}
