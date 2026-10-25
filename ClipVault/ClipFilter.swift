// Purpose: Define the history filters shared by the toolbar and SQLite queries.
import Foundation

enum ClipFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case text = "Text only"
    case images = "Images"
    case pinned = "Pinned"

    var id: Self { self }
}

enum ClipSort: String, CaseIterable, Identifiable {
    case newest = "Newest first"
    case oldest = "Oldest first"
    case pinnedFirst = "Pinned first"

    var id: Self { self }
}
