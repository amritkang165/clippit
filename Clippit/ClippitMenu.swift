// Purpose: Show the live clip count, ten recent clips, and menu actions.
import SwiftUI

struct ClippitMenu: View {
    @ObservedObject var store: ClipStore
    @ObservedObject var settings: SettingsStore
    let onOpenHistory: () -> Void
    let onCopy: (ClipItem) -> Void
    let onClearAll: () -> Void
    let onClearUnpinned: () -> Void
    let onSettings: () -> Void

    var body: some View {
        Text("\(store.items.count) \(store.items.count == 1 ? "clip" : "clips")")
        if settings.capturePaused { Text("Capture paused") }
        Button(settings.capturePaused ? "Resume Capture" : "Pause Capture") {
            settings.capturePaused.toggle()
        }
        Divider()

        ForEach(store.recentItems) { item in
            Button {
                onCopy(item)
            } label: {
                Text(verbatim: item.menuTitle)
            }
        }

        if !store.recentItems.isEmpty { Divider() }
        Button("Open Clippit (\(settings.historyShortcut.display))", action: onOpenHistory)
        Button("Settings…", action: onSettings)
            .keyboardShortcut(",", modifiers: .command)
        Button("Clear unpinned history…", action: onClearUnpinned)
            .disabled(!store.items.contains { !$0.isPinned && !$0.isSnippet })
        Button("Clear all history…", action: onClearAll)
            .disabled(!store.items.contains { !$0.isSnippet })
        Divider()
        Button("Quit") { NSApplication.shared.terminate(nil) }
    }
}
