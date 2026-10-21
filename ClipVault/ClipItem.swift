// Purpose: Represent a locally stored text or image clipboard entry.
import Foundation

struct ClipItem: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let content: String
    var isPinned: Bool
    var imagePath: String? = nil

    var menuTitle: String {
        if imagePath != nil { return "🖼 Image" }
        let singleLine = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.joined(separator: " ")
        if singleLine.isEmpty { return "(Empty text)" }
        return singleLine.count > 40 ? String(singleLine.prefix(39)) + "…" : singleLine
    }
}
