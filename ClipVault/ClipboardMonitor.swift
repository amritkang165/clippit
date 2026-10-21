// Purpose: Poll the clipboard every 0.5 seconds and pass newly copied text or images to storage.

import AppKit

// Owned by AppDelegate and used on the main thread.
final class ClipboardMonitor {
    private let settings: SettingsStore

    init(settings: SettingsStore, pasteboard: NSPasteboard = .general) {
        self.settings = settings
        self.pasteboard = pasteboard
    }

    var onImage: ((Data) -> Void)?
    var onText: ((String) -> Void)?

    private let pasteboard: NSPasteboard
    private var lastCount = 0
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }

        // Only report changes made after monitoring starts.
        lastCount = pasteboard.changeCount

        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        self.timer = timer
        // Continue polling while the menu is open as well.
        RunLoop.main.add(timer, forMode: .common)
    }

    @discardableResult
    func copyToClipboard(_ text: String) -> Bool {
        pasteboard.clearContents()
        let succeeded = pasteboard.setString(text, forType: .string)
        // Do not capture our own restoration as a new history entry.
        lastCount = pasteboard.changeCount
        return succeeded
    }

    @discardableResult
    func copyToClipboard(_ item: ClipItem) throws -> Bool {
        guard let path = item.imagePath else { return copyToClipboard(item.content) }
        // Read and validate before clearing the user's existing clipboard.
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let image = NSImage(data: data), let tiff = image.tiffRepresentation else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let entry = NSPasteboardItem()
        entry.setData(data, forType: .png)
        entry.setData(tiff, forType: .tiff)
        pasteboard.clearContents()
        let succeeded = pasteboard.writeObjects([entry])
        lastCount = pasteboard.changeCount
        return succeeded
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastCount else { return }
        lastCount = currentCount

        if settings.ignorePasswords && shouldIgnorePasswordCopy() { return }

        // Prefer image data when a copy offers both image and text representations.
        for type in [NSPasteboard.PasteboardType.png, .tiff] {
            if let data = pasteboard.data(forType: type), ClipImages.pngData(from: data) != nil {
                onImage?(data)
                return
            }
        }
        // Unsupported or malformed content without a string is skipped.
        guard let text = pasteboard.string(forType: .string) else { return }
        onText?(text)
    }

    private func shouldIgnorePasswordCopy() -> Bool {
        let confidentialTypes = ["org.nspasteboard.ConcealedType", "com.agilebits.onepassword"]
        if confidentialTypes.contains(where: {
            pasteboard.types?.contains(NSPasteboard.PasteboardType($0)) == true
        }) { return true }
        // Source metadata is optional; frontmost application is only a heuristic.
        let source = pasteboard.string(forType: NSPasteboard.PasteboardType("org.nspasteboard.source"))
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return [source, frontmost].compactMap { $0 }.contains { Self.isPasswordApp($0) }
    }

    static func isPasswordApp(_ bundleIdentifier: String) -> Bool {
        let id = bundleIdentifier.lowercased()
        return id == "com.apple.keychainaccess" || id == "com.apple.passwords"
            || id == "com.agilebits.onepassword" || id.hasPrefix("com.agilebits.onepassword")
            || id == "com.1password" || id.hasPrefix("com.1password.")
    }

    deinit {
        timer?.invalidate()
    }
}
