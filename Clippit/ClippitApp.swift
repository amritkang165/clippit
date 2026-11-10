// Purpose: Compose the menu and coordinate clipboard capture, history, hotkey, and confirmation actions.

import AppKit
import SwiftUI

@main
@MainActor
struct ClippitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            if let store = appDelegate.store {
                ClippitMenu(store: store, settings: appDelegate.settings, onOpenHistory: {
                    appDelegate.openHistory()
                }, onCopy: { item in
                    appDelegate.copy(item, andPaste: false)
                }, onClearAll: {
                    appDelegate.confirmClearAll()
                }, onClearUnpinned: {
                    appDelegate.confirmClearAll(keepingPins: true)
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
    private var historyHotKey: HistoryShortcutController?
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
            let controller = HistoryShortcutController { [weak self] in self?.openHistory() }
            historyHotKey = controller
            settings.onShortcutChange = { [weak controller] in try controller?.replace(with: $0) }
            do { try controller.replace(with: settings.historyShortcut) }
            catch { settings.shortcutError = error.localizedDescription }
        } catch {
            showError(error)
        }
    }

    func openHistory() {
        guard let store else { return }
        pasteController.rememberFrontmostApplication()
        if historyWindow == nil {
            let view = HistoryView(store: store, presentation: presentation, settings: settings, onCopy: { [weak self] item in
                self?.copy(item, andPaste: false) ?? false
            }, onCopyAndPaste: { [weak self] item in
                self?.copy(item, andPaste: true) ?? false
            })
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1040, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered, defer: false
            )
            window.title = "Clippit"
            window.contentView = NSHostingView(rootView: view)
            window.minSize = NSSize(width: 760, height: 520)
            window.isReleasedWhenClosed = false
            window.center()
            historyWindow = window
        }
        if let historyWindow { presentation.show(historyWindow) }
    }

    func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 520),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Clippit Settings"
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

    @discardableResult
    func copy(_ item: ClipItem, andPaste: Bool) -> Bool {
        do {
            guard try clipboardMonitor.copyToClipboard(item) else {
                throw CocoaError(.fileWriteUnknown)
            }
        } catch {
            showError(error)
            return false
        }
        if andPaste {
            do { try pasteController.paste(expectedChangeCount: NSPasteboard.general.changeCount) }
            catch { showError(error) }
        }
        return true // Confirms only the completed pasteboard write.
    }

    func confirmClearAll(keepingPins: Bool = false) {
        guard let store, store.items.contains(where: { !$0.isSnippet }), !isConfirmingClear else { return }
        isConfirmingClear = true
        // Let the menu finish closing before presenting a native confirmation dialog.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            defer { isConfirmingClear = false }
            NSApplication.shared.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = keepingPins ? "Clear unpinned history?" : "Clear all clipboard history?"
            alert.informativeText = keepingPins
                ? "This permanently deletes unpinned history and its images. Pinned clips, snippets and your current clipboard stay unchanged."
                : "This permanently deletes clipboard history, including pinned clips and saved images. Snippets and your current clipboard stay unchanged."
            alert.addButton(withTitle: "Cancel")
            let clearButton = alert.addButton(withTitle: keepingPins ? "Clear Unpinned" : "Clear All")
            clearButton.hasDestructiveAction = true
            clearButton.keyEquivalent = ""
            // Return defaults to Cancel; deletion requires choosing Clear All.
            alert.buttons[0].keyEquivalent = "\r"
            alert.buttons[0].keyEquivalentModifierMask = []
            guard alert.runModal() == .alertSecondButtonReturn else { return }
            do {
                if keepingPins { try store.clearUnpinned() }
                else { try store.clearAll() }
            } catch {
                showError(error)
            }
        }
    }

    private func showError(_ error: Error) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert(error: error)
        alert.messageText = "Clippit could not complete the action"
        alert.runModal()
    }

    func applicationWillTerminate(_ notification: Notification) {
        historyHotKey = nil
        clipboardMonitor.stop()
        pasteController.stop()
    }
}
