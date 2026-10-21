// Purpose: Verify repeatable focus requests and full native search-text selection, including Unicode.
import AppKit
import SwiftUI

@MainActor
func checkSearchFocus(in directory: URL) throws {
    _ = NSApplication.shared
    let presentation = HistoryPresentation()
    precondition(presentation.focusRequest == 0)
    presentation.requestSearchFocus()
    presentation.requestSearchFocus()
    precondition(presentation.focusRequest == 2)

    // A hidden window exercises the field editor without activating another application.
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                          styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    defer { window.close() }
    let container = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
    let nested = NSView(frame: container.bounds)
    let field = NSSearchField(frame: NSRect(x: 20, y: 20, width: 300, height: 28))
    nested.addSubview(field)
    container.addSubview(nested)
    window.contentView = container
    precondition(HistorySearchFocus.Coordinator.findSearchField(in: container) === field)
    precondition(HistorySearchFocus.Coordinator.findSearchField(in: NSView()) == nil)
    for query in ["", "existing search", "📋 café 👨‍👩‍👧‍👦"] {
        field.stringValue = query
        precondition(HistorySearchFocus.Coordinator.selectQuery(in: field))
        precondition(field.currentEditor()?.selectedRange == NSRange(location: 0, length: (query as NSString).length))
    }
    let store = try ClipStore(databaseURL: directory.appendingPathComponent("focus/clips.sqlite3"))
    let hosted = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 680),
                          styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
    hosted.isReleasedWhenClosed = false
    defer { hosted.close() }
    hosted.contentView = NSHostingView(rootView: HistoryView(store: store, presentation: presentation,
                                                            onCopy: { _ in }, onCopyAndPaste: { _ in }))
    hosted.contentView?.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    let toolbarField = hosted.toolbar?.items.compactMap { $0 as? NSSearchToolbarItem }.first?.searchField
    let hostedField = toolbarField ?? HistorySearchFocus.Coordinator.findSearchField(in: hosted.contentView?.superview)
    precondition(hostedField != nil, "The actual SwiftUI history must expose its native search field")
    print("PASS: SwiftUI history window search-field integration")
    print("PASS: repeated focus requests, native field lookup, empty/text/Unicode search selection")
}
