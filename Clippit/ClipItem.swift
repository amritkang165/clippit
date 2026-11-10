// Purpose: Represent a locally stored text or image clipboard entry.
import Foundation

struct ClipItem: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let content: String
    var isPinned: Bool
    var imagePath: String? = nil
    var snippetTitle: String? = nil
    var isSnippet: Bool { snippetTitle != nil }

    var menuTitle: String {
        if let snippetTitle { return "Snippet: " + String(snippetTitle.prefix(40)) }
        if imagePath != nil { return "🖼 Image" }
        let singleLine = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.joined(separator: " ")
        if singleLine.isEmpty { return "(Empty text)" }
        return singleLine.count > 40 ? String(singleLine.prefix(39)) + "…" : singleLine
    }
}

// Transformations produce a copy; the stored entry remains unchanged.
enum TextTransform: String, CaseIterable, Identifiable {
    case trim = "Trim whitespace"
    case singleLine = "Single line"
    case uppercase = "UPPERCASE"
    case lowercase = "lowercase"

    var id: Self { self }

    func apply(to text: String) -> String {
        switch self {
        case .trim: return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .singleLine:
            return text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }.joined(separator: " ")
        case .uppercase: return text.uppercased()
        case .lowercase: return text.lowercased()
        }
    }
}

extension ClipItem {
    func transformed(_ transform: TextTransform) -> ClipItem? {
        guard imagePath == nil else { return nil }
        return ClipItem(id: id, timestamp: timestamp, content: transform.apply(to: content),
                        isPinned: isPinned)
    }
}

// Export only text entries; never include image bytes or private filesystem paths.
struct TextHistoryExport: Codable {
    let formatVersion: Int
    let clips: [Entry]

    struct Entry: Codable {
        let id: UUID
        let timestamp: Date
        let content: String
        let isPinned: Bool
        let snippetTitle: String?
    }

    static func encode(_ items: [ClipItem]) throws -> Data {
        let entries = items.filter { $0.imagePath == nil }.map {
            Entry(id: $0.id, timestamp: $0.timestamp, content: $0.content, isPinned: $0.isPinned,
                  snippetTitle: $0.snippetTitle)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(TextHistoryExport(formatVersion: items.contains(where: \.isSnippet) ? 2 : 1, clips: entries))
    }
}
