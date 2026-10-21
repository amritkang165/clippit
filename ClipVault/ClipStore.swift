// Purpose: Persist text and image history, migrate older databases, and prune owned image files.
import Foundation
import Combine
import SQLite

final class ClipStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []
    var recentItems: [ClipItem] { Array(items.prefix(10)) }
    private let db: Connection
    private let clips = Table("clips")
    private let id = SQLite.Expression<String>("id")
    private let ts = SQLite.Expression<Double>("ts")
    private let content = SQLite.Expression<String>("content")
    private let pinned = SQLite.Expression<Int>("pinned")
    private let imagePath = SQLite.Expression<String?>("imagePath")
    private let imageDirectory: URL
    var maxItems = 500
    private var lastSavedContent: String?

    init(databaseURL: URL? = nil) throws {
        let url: URL
        if let databaseURL {
            url = databaseURL
        } else {
            let directory = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true
            ).appendingPathComponent("ClipVault", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            url = directory.appendingPathComponent("clips.sqlite3")
        }
        imageDirectory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        db = try Connection(url.path)
        try db.run(clips.create(ifNotExists: true) { table in
            table.column(id, primaryKey: true)
            table.column(ts)
            table.column(content)
            table.column(pinned, defaultValue: 0)
        })
        // Add the nullable column without discarding Step 3–5 history.
        let columns = try db.prepare("PRAGMA table_info(clips)").map { $0[1] as? String }
        if !columns.contains("imagePath") {
            try db.run(clips.addColumn(imagePath))
        }
        try reload()
        lastSavedContent = items.first?.imagePath == nil ? items.first?.content : nil
        cleanupOrphanImages()
    }

    @discardableResult
    func save(_ text: String) throws -> Bool {
        guard text != lastSavedContent else { return false }
        let item = ClipItem(id: UUID(), timestamp: Date(), content: text, isPinned: false)
        try db.transaction {
            try db.run(clips.insert(
                id <- item.id.uuidString, ts <- item.timestamp.timeIntervalSince1970,
                content <- item.content, pinned <- 0
            ))
            try prune()
        }
        lastSavedContent = text
        try reload()
        cleanupOrphanImages()
        return true
    }

    func saveImage(_ data: Data) throws {
        guard let png = ClipImages.pngData(from: data) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let uuid = UUID()
        let file = imageDirectory.appendingPathComponent("clip-\(uuid.uuidString).png")
        try png.write(to: file, options: .atomic)
        do {
            try db.transaction {
                try db.run(clips.insert(id <- uuid.uuidString, ts <- Date().timeIntervalSince1970,
                                        content <- "Image", pinned <- 0, imagePath <- file.path))
                try prune()
            }
        } catch {
            try? FileManager.default.removeItem(at: file)
            throw error
        }
        lastSavedContent = nil
        try reload()
        cleanupOrphanImages()
    }

    func countToday(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let day = calendar.dateInterval(of: .day, for: now) else { return 0 }
        // Count retained clips, independent of the active search and filter.
        return items.reduce(0) { count, item in
            count + (item.timestamp >= day.start && item.timestamp < day.end ? 1 : 0)
        }
    }

    func search(_ text: String, filter: ClipFilter = .all) throws -> [ClipItem] {
        var query = clips
        if !text.isEmpty {
            // Bind the pattern and escape LIKE metacharacters for literal substring search.
            let escaped = text.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")
            query = query.filter(content.like("%" + escaped + "%", escape: "\\"))
        }
        switch filter {
        case .all: break
        case .text: query = query.filter(imagePath == nil)
        case .images: query = query.filter(imagePath != nil)
        case .pinned: query = query.filter(pinned != 0)
        }
        return try read(query.order(ts.desc, rowid.desc))
    }

    func clearAll() throws {
        try db.transaction {
            try db.run(clips.delete())
        }
        lastSavedContent = nil
        try reload()
        // Surface cleanup failures for an explicit clear instead of silently leaving files.
        try removeOrphanImages()
    }

    func delete(_ itemID: UUID) throws {
        try db.run(clips.filter(id == itemID.uuidString).delete())
        try reload()
        lastSavedContent = items.first?.imagePath == nil ? items.first?.content : nil
        cleanupOrphanImages()
    }

    func setPinned(_ itemID: UUID, to value: Bool) throws {
        try db.transaction {
            try db.run(clips.filter(id == itemID.uuidString).update(pinned <- (value ? 1 : 0)))
            try prune()
        }
        try reload()
        cleanupOrphanImages()
    }

    func enforceLimit(_ limit: Int) throws {
        maxItems = max(1, limit)
        try prune()
        try reload()
        cleanupOrphanImages()
    }

    private func prune() throws {
        // Pinned entries survive pruning, even if pins alone exceed the limit.
        let pinnedCount = try db.scalar(clips.filter(pinned != 0).count)
        let unpinnedLimit = max(0, maxItems - pinnedCount)
        try db.run("""
            DELETE FROM clips WHERE id IN (
                SELECT id FROM clips WHERE pinned = 0
                ORDER BY ts DESC, rowid DESC LIMIT -1 OFFSET ?
            )
            """, unpinnedLimit)
    }

    private func cleanupOrphanImages() {
        do { try removeOrphanImages() }
        catch { NSLog("ClipVault image cleanup failed: %@", error.localizedDescription) }
    }

    private func removeOrphanImages() throws {
        let retained = Set(try db.prepare(clips.select(imagePath)).compactMap { $0[imagePath] }
            .map { URL(fileURLWithPath: $0).resolvingSymlinksInPath().standardizedFileURL.path })
        for file in try FileManager.default.contentsOfDirectory(at: imageDirectory, includingPropertiesForKeys: nil) {
            let name = file.deletingPathExtension().lastPathComponent
            // Never remove arbitrary files, even if a database path is malformed.
            guard file.pathExtension == "png", name.hasPrefix("clip-"),
                  UUID(uuidString: String(name.dropFirst(5))) != nil,
                  !retained.contains(file.resolvingSymlinksInPath().standardizedFileURL.path) else { continue }
            try FileManager.default.removeItem(at: file)
        }
    }

    private func reload() throws {
        items = try read(clips.order(ts.desc, rowid.desc))
    }

    private func read(_ query: Table) throws -> [ClipItem] {
        try db.prepare(query).map { row in
            guard let uuid = UUID(uuidString: row[id]) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return ClipItem(id: uuid, timestamp: Date(timeIntervalSince1970: row[ts]),
                            content: row[content], isPinned: row[pinned] != 0, imagePath: row[imagePath])
        }
    }
}
