// Purpose: Verify login-item state handling without changing the host, and local-day statistics across DST.
import AppKit
import ServiceManagement
import SQLite

@MainActor
private final class FakeLoginService: LoginItemServicing {
    var status: SMAppService.Status = .notRegistered
    var nextStatus: SMAppService.Status = .enabled
    var registrationCount = 0
    var removalCount = 0
    var shouldFail = false
    func register() throws {
        registrationCount += 1
        if shouldFail { throw CocoaError(.fileWriteNoPermission) }
        status = nextStatus
    }
    func unregister() throws {
        removalCount += 1
        if shouldFail { throw CocoaError(.fileWriteNoPermission) }
        status = .notRegistered
    }
}

@MainActor
func checkPolish(in directory: URL) throws {
    let service = FakeLoginService()
    let login = LoginItemStore(service: service, isAppBundle: true)
    precondition(service.registrationCount == 0 && !login.isRequested)
    try login.setEnabled(true)
    try login.setEnabled(true)
    precondition(login.status == .enabled && service.registrationCount == 1)
    service.status = .requiresApproval
    login.refresh()
    precondition(login.isRequested && login.status == .requiresApproval)
    try login.setEnabled(false)
    precondition(!login.isRequested && service.removalCount == 1)
    service.nextStatus = .requiresApproval
    try login.setEnabled(true)
    precondition(login.status == .requiresApproval)
    try login.setEnabled(false)
    service.shouldFail = true
    do {
        try login.setEnabled(true)
        preconditionFailure("Registration error must propagate")
    } catch { precondition(!login.isRequested && login.status == .notRegistered) }
    let calls = service.registrationCount
    let unbundled = LoginItemStore(service: service, isAppBundle: false)
    do {
        try unbundled.setEnabled(true)
        preconditionFailure("Unbundled tools cannot register as the main app")
    } catch { precondition(service.registrationCount == calls) }

    for zone in ["Asia/Kolkata", "America/Los_Angeles"] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12))!
        let day = calendar.dateInterval(of: .day, for: now)!
        if zone == "America/Los_Angeles" { precondition(day.duration == 25 * 3_600) }
        let folder = directory.appendingPathComponent(zone.replacingOccurrences(of: "/", with: "-"))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("stats.sqlite3")
        _ = try ClipStore(databaseURL: url)
        let db = try Connection(url.path)
        for (index, date) in [day.start.addingTimeInterval(-1), day.start, now, day.end.addingTimeInterval(-1), day.end].enumerated() {
            try db.run("INSERT INTO clips (id, ts, content, pinned) VALUES (?, ?, ?, ?)",
                       UUID().uuidString, date.timeIntervalSince1970, "date \(index)", 0)
        }
        let store = try ClipStore(databaseURL: url)
        precondition(store.countToday(now: now, calendar: calendar) == 3)
        _ = try store.search("no match", filter: .pinned)
        precondition(store.countToday(now: now, calendar: calendar) == 3)
        let todayItem = store.items.first { $0.timestamp == now }!
        try store.delete(todayItem.id)
        precondition(store.countToday(now: now, calendar: calendar) == 2)
        try store.clearAll()
        precondition(store.countToday(now: now, calendar: calendar) == 0)
    }
    print("PASS: opt-in login registration, approval/revocation, duplicate-toggle guard, errors, unbundled guard")
    print("PASS: local-day counts, midnight boundaries, 25-hour DST day, search independence, deletion and clearing")
}
