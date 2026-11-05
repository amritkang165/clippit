// Purpose: Remember the previous app and paste there after explicit Copy and Paste actions.
import AppKit
import ApplicationServices
import Carbon.HIToolbox

@MainActor
final class PasteController {
    private var previousApplication: NSRunningApplication?
    private var activationObserver: NSObjectProtocol?
    private var pendingPaste: Task<Void, Never>?
    var onError: ((Error) -> Void)?

    func start() {
        rememberFrontmostApplication()
        guard activationObserver == nil else { return }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor [weak self] in self?.remember(app) }
        }
    }

    func rememberFrontmostApplication() {
        if let app = NSWorkspace.shared.frontmostApplication { remember(app) }
    }

    private func remember(_ app: NSRunningApplication) {
        if app.processIdentifier != ProcessInfo.processInfo.processIdentifier && app.activationPolicy == .regular {
            previousApplication = app
        }
    }

    func paste(expectedChangeCount: Int) throws {
        pendingPaste?.cancel()
        guard let target = previousApplication, !target.isTerminated else {
            throw PasteError.noTarget
        }
        guard AXIsProcessTrusted() else {
            // Only request this when the user explicitly invokes Copy and Paste.
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            throw PasteError.accessibilityRequired
        }
        NSApplication.shared.yieldActivation(to: target)
        NSApplication.shared.hide(nil)
        guard target.activate(options: []) else { throw PasteError.activationFailed }
        pendingPaste = Task { @MainActor [weak self] in
            do {
                // Wait for activation and shortcut-key release, with a bounded timeout.
                for _ in 0..<30 {
                    try await Task.sleep(nanoseconds: 50_000_000)
                    guard !target.isTerminated else { throw PasteError.noTarget }
                    let flags = CGEventSource.flagsState(.combinedSessionState)
                    let held = flags.intersection([.maskCommand, .maskShift, .maskControl, .maskAlternate])
                    guard NSWorkspace.shared.frontmostApplication?.processIdentifier == target.processIdentifier,
                          held.isEmpty else { continue }
                    guard NSPasteboard.general.changeCount == expectedChangeCount else {
                        throw PasteError.clipboardChanged
                    }
                    guard let source = CGEventSource(stateID: .privateState),
                          let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
                          let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
                        throw PasteError.eventFailed
                    }
                    down.flags = .maskCommand
                    up.flags = .maskCommand
                    // Address the chosen process, so a focus race cannot paste into a different app.
                    down.postToPid(target.processIdentifier)
                    up.postToPid(target.processIdentifier)
                    return
                }
                throw PasteError.activationFailed
            } catch is CancellationError {
                return
            } catch {
                self?.onError?(error)
            }
        }
    }

    func stop() {
        pendingPaste?.cancel()
        pendingPaste = nil
        if let activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(activationObserver) }
        activationObserver = nil
    }
}

enum PasteError: LocalizedError {
    case noTarget, accessibilityRequired, activationFailed, eventFailed, clipboardChanged

    var errorDescription: String? {
        switch self {
        case .clipboardChanged:
            return "The clipboard changed before pasting. Select the clip and try Copy and Paste again."
        case .noTarget:
            return "The clip was copied. Open the app you want to paste into, then reopen Clippit and try again."
        case .accessibilityRequired:
            return "The clip was copied. Enable Clippit in System Settings → Privacy & Security → Accessibility, then retry Copy and Paste."
        case .activationFailed:
            return "The clip was copied, but the destination app could not be activated or shortcut keys remained held. Paste manually with ⌘V."
        case .eventFailed:
            return "The clip was copied, but the paste keystroke could not be created. Paste manually with ⌘V."
        }
    }
}
