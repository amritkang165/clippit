// Purpose: Exercise real on-device Vision OCR with generated images and isolated files.
import AppKit
import Vision

@MainActor func checkImageTextRecognition() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    func fixture(_ name: String, text: String?) throws -> URL {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1400, pixelsHigh: 400,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: 1400, height: 400).fill()
        if let text {
            (text as NSString).draw(at: NSPoint(x: 50, y: 180), withAttributes: [
                .font: NSFont.systemFont(ofSize: 72), .foregroundColor: NSColor.black
            ])
        }
        NSGraphicsContext.restoreGraphicsState()
        let url = directory.appendingPathComponent(name)
        try bitmap.representation(using: .png, properties: [:])!.write(to: url)
        return url
    }

    print("OCR environment: \(ProcessInfo.processInfo.operatingSystemVersionString), Vision default revision \(VNRecognizeTextRequest.defaultRevision), supported \(VNRecognizeTextRequest.supportedRevisions)")
    #if arch(arm64)
    print("OCR hardware architecture: arm64")
    #else
    print("OCR hardware architecture: x86_64")
    #endif
    let recognizer = ImageTextRecognizer()
    let image = try fixture("text.png", text: "Clippit 12345")
    let original = try Data(contentsOf: image)
    let result = try await recognizer.recognize(at: image)
    precondition(result.contains("Clippit") && result.contains("12345"), "Unexpected OCR: \(result)")
    let cpuResult = try await recognizer.recognize(at: image, cpuOnly: true)
    precondition(cpuResult.contains("Clippit") && cpuResult.contains("12345"), "CPU OCR did not recognize the generated fixture")
    let unchanged = try Data(contentsOf: image)
    precondition(unchanged == original)

    let blank = try fixture("blank.png", text: nil)
    let empty = try await recognizer.recognize(at: blank)
    precondition(empty.isEmpty)
    let corrupt = directory.appendingPathComponent("corrupt.png")
    try Data("not an image".utf8).write(to: corrupt)
    for invalid in [corrupt, directory.appendingPathComponent("missing.png"),
                    URL(string: "https://example.invalid/image.png")!] {
        do {
            _ = try await recognizer.recognize(at: invalid)
            preconditionFailure("Invalid images must fail")
        } catch ImageTextRecognizer.RecognitionError.invalidImage { }
    }

    let cancelled = Task { try await recognizer.recognize(at: image) }
    cancelled.cancel()
    do {
        _ = try await cancelled.value
        preconditionFailure("Cancelled OCR must not return a result")
    } catch is CancellationError { }

    // Copy the recognized string through the same monitor path used by history,
    // keeping this test completely separate from the system clipboard.
    let suite = "ClippitOCR.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let board = NSPasteboard.withUniqueName()
    defer { board.releaseGlobally() }
    let monitor = ClipboardMonitor(settings: SettingsStore(defaults: defaults), pasteboard: board)
    let textClip = ClipItem(id: UUID(), timestamp: Date(), content: result, isPinned: false)
    let copied = try monitor.copyToClipboard(textClip)
    precondition(copied && board.string(forType: .string) == result)
    precondition(board.data(forType: .png) == nil)
    print("PASS: real Vision OCR, blank/invalid images, cancellation, unchanged image, and text copying")
}
