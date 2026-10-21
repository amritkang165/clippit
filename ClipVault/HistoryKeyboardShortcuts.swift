// Purpose: Handle history shortcuts only in its window, preserving search-field text editing.
import AppKit
import SwiftUI

enum HistoryAction: Equatable {
    case copy, copyAndPaste, delete

    static func matching(keyCode: UInt16, characters: String?, modifiers: NSEvent.ModifierFlags,
                         editingText: Bool) -> HistoryAction? {
        guard !editingText else { return nil }
        let flags = modifiers.intersection([.command, .shift, .control, .option])
        if characters?.lowercased() == "c" {
            if flags == [.command, .shift] { return .copyAndPaste }
            if flags == [.command] { return .copy }
        }
        if (keyCode == 51 || keyCode == 117) && flags.isEmpty { return .delete }
        return nil
    }
}

struct HistoryKeyboardShortcuts: NSViewRepresentable {
    var perform: (HistoryAction) -> Bool

    func makeCoordinator() -> Coordinator { Coordinator(perform: perform) }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.view = view
        context.coordinator.start()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.perform = perform
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator {
        weak var view: NSView?
        var perform: (HistoryAction) -> Bool
        private var token: Any?

        init(perform: @escaping (HistoryAction) -> Bool) { self.perform = perform }

        func start() {
            guard token == nil else { return }
            token = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, let window = view?.window,
                      event.window === window, window.isKeyWindow, window.attachedSheet == nil,
                      let action = HistoryAction.matching(keyCode: event.keyCode,
                          characters: event.charactersIgnoringModifiers, modifiers: event.modifierFlags,
                          editingText: window.firstResponder is NSTextView) else { return event }
                // Holding Delete should not unexpectedly remove multiple entries.
                if event.isARepeat { return nil }
                return perform(action) ? nil : event
            }
        }

        func stop() {
            if let token { NSEvent.removeMonitor(token) }
            token = nil
        }

        deinit { stop() }
    }
}
