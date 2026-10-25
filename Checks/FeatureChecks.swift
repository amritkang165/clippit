// Purpose: Check text transformations and history tools against isolated fixtures.
import Foundation
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
    print("PASS: deterministic SQLite sort modes with filters and timestamp ties")
    print("PASS: immutable text transformations, Unicode case conversion, and image exclusion")
}
