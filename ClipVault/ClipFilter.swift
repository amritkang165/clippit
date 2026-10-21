// Purpose: Define the history filters shared by the toolbar and SQLite queries.
import Foundation

enum ClipFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case text = "Text only"
    case images = "Images"
    case pinned = "Pinned"

    var id: Self { self }
}
