// Purpose: Verify real SQLite queries, combined filters, deletion, and shortcut text-editing guards.
import AppKit
import SQLite

func checkSearch(in directory: URL) throws {
    let url = directory.appendingPathComponent("search/clips.sqlite3")
    let store = try ClipStore(databaseURL: url)
    for text in ["Alpha", "100% literal", "under_score", "back\\slash", "O'Reilly", "βήτα"] {
        try store.save(text)
    }
    let alpha = try store.search("alpha")[0]
    try store.setPinned(alpha.id, to: true)
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    for y in 0..<2 {
        for x in 0..<2 { bitmap.setColor(NSColor(deviceWhite: 0.5, alpha: 1), atX: x, y: y) }
    }
    try store.saveImage(bitmap.representation(using: .png, properties: [:])!)
    let image = store.items[0]
    try store.setPinned(image.id, to: true)
    let all = try store.search("")
    let text = try store.search("", filter: .text)
    let images = try store.search("", filter: .images)
    let pinned = try store.search("", filter: .pinned)
    precondition(all.count == 7 && text.count == 6 && images.map(\.id) == [image.id])
    precondition(pinned.map(\.id) == [image.id, alpha.id])
    let pinnedSearch = try store.search("alpha", filter: .pinned)
    let unmatched = try store.search("alpha", filter: .images)
    precondition(pinnedSearch.map(\.id) == [alpha.id] && unmatched.isEmpty)
    for (query, expected) in [("%", "100% literal"), ("_", "under_score"), ("\\", "back\\slash"),
                              ("'", "O'Reilly"), ("βήτα", "βήτα")] {
        let results = try store.search(query)
        precondition(results.map(\.content) == [expected])
    }
    let injection = try store.search("' OR 1=1 --")
    precondition(injection.isEmpty)

    // A second SQLite connection inserts a row unknown to the in-memory published list.
    let db = try Connection(url.path)
    let externalID = UUID()
    try db.run("INSERT INTO clips (id, ts, content, pinned) VALUES (?, ?, ?, ?)",
               externalID.uuidString, Date().timeIntervalSince1970 + 1, "database-only", 0)
    precondition(!store.items.contains { $0.id == externalID })
    let fromDatabase = try store.search("database-only")
    precondition(fromDatabase.map(\.id) == [externalID])

    try store.delete(image.id)
    precondition(!FileManager.default.fileExists(atPath: image.imagePath!))
    let imageResults = try store.search("", filter: .images)
    precondition(imageResults.isEmpty)
    try store.delete(alpha.id)
    let pinResults = try store.search("", filter: .pinned)
    precondition(pinResults.isEmpty)
    try store.save("delete and recopy")
    try store.delete(store.items.first { $0.content == "delete and recopy" }!.id)
    let recopied = try store.save("delete and recopy")
    precondition(recopied)

    precondition(HistoryAction.matching(keyCode: 8, characters: "c", modifiers: .command, editingText: false) == .copy)
    precondition(HistoryAction.matching(keyCode: 8, characters: "C", modifiers: [.command, .shift], editingText: false) == .copyAndPaste)
    precondition(HistoryAction.matching(keyCode: 51, characters: nil, modifiers: [], editingText: false) == .delete)
    precondition(HistoryAction.matching(keyCode: 117, characters: nil, modifiers: [], editingText: false) == .delete)
    precondition(HistoryAction.matching(keyCode: 51, characters: nil, modifiers: .command, editingText: false) == nil)
    for action in [(UInt16(8), "c", NSEvent.ModifierFlags.command),
                   (UInt16(8), "C", NSEvent.ModifierFlags([.command, .shift])),
                   (UInt16(51), "", NSEvent.ModifierFlags())] {
        precondition(HistoryAction.matching(keyCode: action.0, characters: action.1, modifiers: action.2, editingText: true) == nil)
    }
    print("PASS: database-backed LIKE, literal wildcard escaping, bound search input, all four filters, combined search/filter")
    print("PASS: deletion of text and pinned images, file cleanup, recopy after deletion, shortcut mappings and text-editing guards")
}
