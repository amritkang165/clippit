// Purpose: Exercise snippet copying and configurable shortcut presentation using disposable UI and pasteboard fixtures.
import AppKit
import SwiftUI
import ServiceManagement

private final class CheckRegistration: ShortcutRegistration {}

@MainActor private final class PreviewLoginService: LoginItemServicing {
    var status: SMAppService.Status { .notRegistered }
    func register() throws { preconditionFailure("Preview must not register a login item") }
    func unregister() throws { preconditionFailure("Preview must not unregister a login item") }
}

@MainActor func checkRequestedFeatures(in directory: URL) throws {
    let suite = "ClippitFeatureUI.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = SettingsStore(defaults: defaults)
    let store = try ClipStore(databaseURL: directory.appendingPathComponent("snippets.sqlite3"))
    try store.save("A disposable clipboard example")
    let id = try store.saveSnippet(title: "Friendly reply 👋", text: "Thanks for the update!\nI’ll take a look shortly.")
    let snippet = store.items.first { $0.id == id }!
    let board = NSPasteboard.withUniqueName()
    defer { board.releaseGlobally() }
    let monitor = ClipboardMonitor(settings: settings, pasteboard: board)
    var captures = 0
    monitor.onText = { _ in captures += 1 }
    monitor.start()
    defer { monitor.stop() }
    let copied = try monitor.copyToClipboard(snippet)
    precondition(copied)
    RunLoop.main.run(until: Date().addingTimeInterval(0.6))
    precondition(board.string(forType: .string) == snippet.content && captures == 0)
    precondition(store.items.count == 2)

    let presentation = HistoryPresentation()
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 700),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    defer { window.close() }
    window.contentView = NSHostingView(rootView: HistoryView(store: store, presentation: presentation,
        settings: settings, onCopy: { _ in true }, onCopyAndPaste: { _ in true }))
    var callback: (() -> Void)?
    let controller = HistoryShortcutController(register: { _, action in
        callback = action
        return CheckRegistration()
    }, action: { presentation.show(window, activate: {}) })
    settings.onShortcutChange = { try controller.replace(with: $0) }
    let shortcut = HistoryShortcut(keyCode: 11, modifiers: NSEvent.ModifierFlags([.control, .option]).rawValue)
    try settings.setHistoryShortcut(shortcut)
    window.contentView?.layoutSubtreeIfNeeded()
    callback?()
    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    precondition(window.isVisible && presentation.focusRequest == 1)
    window.close()
    callback?()
    precondition(window.isVisible && presentation.focusRequest == 2)
    window.miniaturize(nil)
    RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    precondition(window.isMiniaturized, "Fixture must exercise an actually minimized window")
    callback?()
    RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    precondition(!window.isMiniaturized && presentation.focusRequest == 3)
    let search = window.toolbar?.items.compactMap { $0 as? NSSearchToolbarItem }.first?.searchField
    if let search {
        search.stringValue = "café 👋"
        precondition(HistorySearchFocus.Coordinator.selectQuery(in: search))
        precondition(search.currentEditor()?.selectedRange.length == (search.stringValue as NSString).length)
    } else { preconditionFailure("History search field missing") }

    if let output = ProcessInfo.processInfo.environment["CLIPPIT_CHECK_SCREENSHOTS"] {
        let folder = URL(fileURLWithPath: output, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        func render<V: View>(_ name: String, view: V, size: NSSize, dark: Bool = false) throws {
            let host = NSHostingView(rootView: view)
            host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
            let preview = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled],
                                   backing: .buffered, defer: false)
            preview.isReleasedWhenClosed = false
            defer { preview.close() }
            preview.contentView = host
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.3))
            guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
                preconditionFailure("No view bitmap")
            }
            host.cacheDisplay(in: host.bounds, to: bitmap)
            try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(name + ".png"))
        }
        for dark in [false, true] {
            let suffix = dark ? "dark" : "light"
            try render("history-" + suffix,
                       view: HistoryView(store: store, presentation: HistoryPresentation(), settings: settings,
                                         onCopy: { _ in true }, onCopyAndPaste: { _ in true }),
                       size: NSSize(width: 1040, height: 700), dark: dark)
            try render("settings-" + suffix,
                       view: SettingsView(settings: settings, loginItem: LoginItemStore(service: PreviewLoginService(), isAppBundle: false)),
                       size: NSSize(width: 500, height: 520), dark: dark)
        }
        try render("snippet-editor", view: SnippetEditor(draft: SnippetDraft(item: snippet), save: { _, _ in }),
                   size: NSSize(width: 528, height: 380))
    }
    print("PASS: snippet copy without recapture, new shortcut action, reopen, unminimize and Unicode search selection")
}
