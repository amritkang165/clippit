// Purpose: Define the history filters shared by the toolbar and SQLite queries.
import Foundation

enum ClipFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case text = "Text only"
    case images = "Images"
    case pinned = "Pinned"
    case snippets = "Snippets"

    var id: Self { self }
}

enum ClipSort: String, CaseIterable, Identifiable {
    case newest = "Newest first"
    case oldest = "Oldest first"
    case pinnedFirst = "Pinned first"

    var id: Self { self }
}

// SF Symbols for the history navigation controls.
extension ClipFilter {
    var symbol: String {
        switch self {
        case .all: return "square.stack"
        case .text: return "text.alignleft"
        case .images: return "photo"
        case .pinned: return "pin"
        case .snippets: return "text.badge.plus"
        }
    }
}
