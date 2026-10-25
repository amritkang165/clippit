// Purpose: Compose the menu and coordinate clipboard capture, history, hotkey, and confirmation actions.

import AppKit
import SwiftUI
import HotKey

@main
@MainActor
struct ClipVaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            if let store = appDelegate.store {
                ClipVaultMenu(store: store, settings: appDelegate.settings, onOpenHistory: {
                    appDelegate.openHistory()
                }, onCopy: { item in
                    appDelegate.copy(item, andPaste: false)
                }, onClearAll: {
                    appDelegate.confirmClearAll()
                }, onSettings: {
                    appDelegate.openSettings()
                })
            } else {
                Text("History unavailable")
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        } label: {
            Text("📋")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var historyHotKey: HotKey?
    private let presentation = HistoryPresentation()
    private let pasteController = PasteController()
    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private let loginItem = LoginItemStore()
    @Published private(set) var store: ClipStore?
    private var isConfirmingClear = false
    let settings = SettingsStore()
    private lazy var clipboardMonitor = ClipboardMonitor(settings: settings)

    func applicationDidFinishLaunching(_ notification: Notification) {
        pasteController.onError = { [weak self] error in self?.showError(error) }
        pasteController.start()
        do {
            let store = try ClipStore()
            try store.enforceLimit(settings.maxItems)
            self.store = store
            settings.onMaxItemsChange = { [weak self] limit in
                do {
                    try store.enforceLimit(limit)
                } catch {
                    self?.showError(error)
                }
            }
            clipboardMonitor.onText = { [weak self] text in
                do {
                    try store.save(text)
                } catch {
                    self?.showError(error)
                }
            }
            clipboardMonitor.onImage = { [weak self] data in
                do {
                    try store.saveImage(data)
                } catch {
                    self?.showError(error)
                }
            }
            clipboardMonitor.start()
            historyHotKey = HotKey(key: .v, modifiers: [.command, .shift])
            historyHotKey?.keyDownHandler = { [weak self] in
                Task { @MainActor [weak self] in self?.openHistory() }
            }
        } catch {
            showError(error)
        }
    }

    func openHistory() {
        guard let store else { return }
        pasteController.rememberFrontmostApplication()
        if historyWindow == nil {
            let view = HistoryView(store: store, presentation: presentation, onCopy: { [weak self] item in
                self?.copy(item, andPaste: false)
            }, onCopyAndPaste: { [weak self] item in
                self?.copy(item, andPaste: true)
            })
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 960, height: 680),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            window.title = "ClipVault"
            window.contentView = NSHostingView(rootView: view)
            window.minSize = NSSize(width: 760, height: 520)
            window.isReleasedWhenClosed = false
            window.center()
            historyWindow = window
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        if historyWindow?.isMiniaturized == true { historyWindow?.deminiaturize(nil) }
        historyWindow?.makeKeyAndOrderFront(nil)
        presentation.requestSearchFocus()
    }

    func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 520),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "ClipVault Settings"
            window.contentView = NSHostingView(rootView: SettingsView(settings: settings, loginItem: loginItem))
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        loginItem.refresh()
        NSApplication.shared.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func copy(_ item: ClipItem, andPaste: Bool) {
        do {
            guard try clipboardMonitor.copyToClipboard(item) else {
                throw CocoaError(.fileWriteUnknown)
            }
            if andPaste { try pasteController.paste(expectedChangeCount: NSPasteboard.general.changeCount) }
        } catch {
            showError(error)
        }
    }

    func confirmClearAll() {
        guard let store, !store.items.isEmpty, !isConfirmingClear else { return }
        isConfirmingClear = true
        // Let the menu finish closing before presenting a native confirmation dialog.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            defer { isConfirmingClear = false }
            NSApplication.shared.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Clear all clipboard history?"
            alert.informativeText = "This permanently deletes all saved clips, including pinned clips and saved images. Your current clipboard stays unchanged."
            alert.addButton(withTitle: "Cancel")
            let clearButton = alert.addButton(withTitle: "Clear All")
            clearButton.hasDestructiveAction = true
            clearButton.keyEquivalent = ""
            // Return defaults to Cancel; deletion requires choosing Clear All.
            alert.buttons[0].keyEquivalent = "\r"
            alert.buttons[0].keyEquivalentModifierMask = []
            guard alert.runModal() == .alertSecondButtonReturn else { return }
            do {
                try store.clearAll()
            } catch {
                showError(error)
            }
        }
    }

    private func showError(_ error: Error) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert(error: error)
        alert.messageText = "ClipVault could not complete the action"
        alert.runModal()
    }

    func applicationWillTerminate(_ notification: Notification) {
        historyHotKey = nil
        clipboardMonitor.stop()
        pasteController.stop()
    }
}
