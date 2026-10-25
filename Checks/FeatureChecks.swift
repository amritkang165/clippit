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
    print("PASS: immutable text transformations, Unicode case conversion, and image exclusion")
}
