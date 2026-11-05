// Purpose: Focus and select the native searchable field on macOS 14 when history opens.
import AppKit
import Combine
import SwiftUI

final class HistoryPresentation: ObservableObject {
    @Published private(set) var focusRequest = 0

    func requestSearchFocus() {
        focusRequest += 1
    }
}

struct HistorySearchFocus: NSViewRepresentable {
    let request: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.focus(request: request)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.cancel()
    }

    @MainActor
    final class Coordinator {
        weak var view: NSView?
        private var lastRequest = 0
        private var task: Task<Void, Never>?

        func focus(request: Int) {
            guard request > 0, request != lastRequest else { return }
            lastRequest = request
            task?.cancel()
            task = Task { @MainActor [weak self] in
                // SwiftUI may attach the toolbar after the window becomes key.
                for _ in 0..<40 {
                    do { try await Task.sleep(nanoseconds: 25_000_000) }
                    catch { return }
                    guard let self else { return }
                    guard let window = view?.window, window.isKeyWindow, window.attachedSheet == nil else { continue }
                    if let item = window.toolbar?.items.compactMap({ $0 as? NSSearchToolbarItem }).first {
                        item.beginSearchInteraction()
                        if Self.selectQuery(in: item.searchField) { return }
                    } else if let field = Self.findSearchField(in: window.contentView?.superview) {
                        if Self.selectQuery(in: field) { return }
                    }
                }
            }
        }

        static func findSearchField(in view: NSView?) -> NSSearchField? {
            guard let view else { return nil }
            if let field = view as? NSSearchField { return field }
            for child in view.subviews {
                if let field = findSearchField(in: child) { return field }
            }
            return nil
        }

        @discardableResult
        static func selectQuery(in field: NSSearchField) -> Bool {
            guard let window = field.window, window.makeFirstResponder(field) else { return false }
            field.selectText(nil)
            guard let editor = field.currentEditor() else { return false }
            editor.selectedRange = NSRange(location: 0, length: (field.stringValue as NSString).length)
            return true
        }

        func cancel() {
            task?.cancel()
            task = nil
        }
    }
}
