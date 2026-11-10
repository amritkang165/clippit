// Purpose: Record a shortcut in a focused sheet without installing a global key listener.
import SwiftUI
import AppKit

struct ShortcutRecorder: View {
    let onRecord: (HistoryShortcut) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 18) {
            Text("Press your new shortcut").font(.headline)
            Text("Use Command or Control with a letter, number, Space or F1–F12.")
                .multilineTextAlignment(.center)
            CaptureKey { shortcut in
                if let shortcut { onRecord(shortcut) }
                dismiss()
            }.frame(width: 320, height: 32)
            Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
        }.padding(24).frame(width: 380)
            .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct CaptureKey: NSViewRepresentable {
    let completion: (HistoryShortcut?) -> Void
    func makeNSView(context: Context) -> KeyView {
        let view = KeyView()
        view.completion = completion
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.textField)
        view.setAccessibilityLabel("Press a keyboard shortcut. Escape cancels.")
        return view
    }
    func updateNSView(_ nsView: KeyView, context: Context) { nsView.completion = completion }
    final class KeyView: NSView {
        var completion: ((HistoryShortcut?) -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                window?.makeFirstResponder(self)
            }
        }
        override func keyDown(with event: NSEvent) {
            if event.keyCode == 53 { completion?(nil); return }
            let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
            completion?(HistoryShortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers.rawValue))
        }
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            guard window?.firstResponder === self else { return false }
            keyDown(with: event)
            return true
        }
    }
}
