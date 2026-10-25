// Purpose: Verify capture controls using isolated preferences and a private pasteboard.
import AppKit

@MainActor func checkCaptureControls() {
    let suite = "ClipVaultCapture.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = SettingsStore(defaults: defaults)
    settings.ignorePasswords = false
    precondition(!settings.capturePaused)
    let board = NSPasteboard.withUniqueName()
    defer { board.releaseGlobally() }
    let monitor = ClipboardMonitor(settings: settings, pasteboard: board)
    var captured: [String] = []
    monitor.onText = { captured.append($0) }
    monitor.start()
    defer { monitor.stop() }
    func write(_ text: String) {
        board.clearContents()
        board.setString(text, forType: .string)
    }
    func poll() { RunLoop.main.run(until: Date().addingTimeInterval(0.65)) }
    settings.capturePaused = true
    precondition(SettingsStore(defaults: defaults).capturePaused)
    write("private while paused")
    poll()
    precondition(captured.isEmpty)
    write("between ticks")
    settings.capturePaused = false
    poll()
    precondition(captured.isEmpty)
    write("resumed")
    poll()
    precondition(captured == ["resumed"])
    settings.maxTextCharacters = 2
    precondition(SettingsStore(defaults: defaults).maxTextCharacters == 2)
    write("abc")
    poll()
    precondition(captured == ["resumed"])
    precondition(board.string(forType: .string) == "abc")
    write("👨‍👩‍👧‍👦é")
    poll()
    precondition(captured.last == "👨‍👩‍👧‍👦é")
    settings.maxTextCharacters = -1
    precondition(settings.maxTextCharacters == 0)
    write("unlimited again")
    poll()
    precondition(captured.last == "unlimited again")
    print("PASS: Unicode text limits, persistence, and untouched oversized clipboard")
    print("PASS: paused capture, persisted preference, and no replay on resume")
}
