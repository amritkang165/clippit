// Purpose: Present a refined history browser with SQLite filters, native search, and a full clip preview.
import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @ObservedObject var store: ClipStore
    @ObservedObject var presentation: HistoryPresentation
    @ObservedObject var settings: SettingsStore
    let onCopy: (ClipItem) -> Bool
    let onCopyAndPaste: (ClipItem) -> Bool
    @StateObject private var copyFeedback = CopyFeedback()
    @State private var snippetDraft: SnippetDraft?
    @State private var snippetToDelete: ClipItem?
    @State private var isSearchPresented = false
    @State private var searchText = ""
    @State private var selection: UUID?
    @State private var errorMessage: String?
    @State private var filter: ClipFilter = .all
    @State private var sort: ClipSort = .newest
    @State private var visibleItems: [ClipItem] = []

    private var selectedItem: ClipItem? { visibleItems.first { $0.id == selection } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        if geometry.size.width >= 940 {
                            librarySidebar.frame(width: 176)
                            Rectangle().fill(VaultStyle.line).frame(width: 1)
                        }
                        VStack(spacing: 0) {
                            if geometry.size.width < 940 {
                                header
                                Rectangle().fill(VaultStyle.line).frame(height: 1)
                            }
                            if store.items.isEmpty {
                                emptyHistory
                            } else {
                                historyPanels(width: geometry.size.width - (geometry.size.width >= 940 ? 177 : 0))
                            }
                        }
                    }
                }
                footer
            }
            .background(VaultStyle.canvas)
            .searchable(text: $searchText, isPresented: $isSearchPresented, placement: .toolbar, prompt: "Search your clipboard")
            .navigationTitle("Clippit")
            .toolbar {
                ToolbarItem {
                    Button { snippetDraft = SnippetDraft() } label: {
                        Label("New snippet", systemImage: "text.badge.plus")
                    }
                }
                ToolbarItem {
                    Button { exportText() } label: {
                        Label("Export visible text…", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!visibleItems.contains { $0.imagePath == nil })
                    .help("Export text from the current search and filter as a JSON file.")
                }
                ToolbarItem {
                    Menu {
                        Picker("Sort history", selection: $sort) {
                            ForEach(ClipSort.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: { Label("Sort history", systemImage: "arrow.up.arrow.down") }
                    .help("Sort history")
                }
            }
            .background {
                HistoryKeyboardShortcuts { action in
                    guard let item = selectedItem else { return false }
                    switch action {
                    case .copy: copy(item)
                    case .copyAndPaste: copy(item, andPaste: true)
                    case .delete: delete(item)
                    }
                    return true
                }
                .frame(width: 0, height: 0)
            }
            .background {
                HistorySearchFocus(request: presentation.focusRequest).frame(width: 0, height: 0)
            }
            .onAppear {
                refreshResults()
                if presentation.focusRequest > 0 { isSearchPresented = true }
            }
            .onChange(of: presentation.focusRequest) { _, _ in isSearchPresented = true }
            .onChange(of: searchText) { _, _ in refreshResults() }
            .onChange(of: sort) { _, _ in refreshResults() }
            .onChange(of: filter) { _, _ in refreshResults() }
            .onChange(of: store.items) { _, _ in refreshResults() }
            .alert("Could not update history", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
        .sheet(item: $snippetDraft) { draft in
            SnippetEditor(draft: draft) { title, text in
                let id = try store.saveSnippet(title: title, text: text, editing: draft.existingID)
                filter = .snippets
                searchText = ""
                refreshResults()
                selection = id
            }
        }
        .confirmationDialog("Delete this snippet permanently?", isPresented: Binding(
            get: { snippetToDelete != nil }, set: { if !$0 { snippetToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete snippet", role: .destructive) {
                if let item = snippetToDelete { deleteConfirmed(item) }
                snippetToDelete = nil
            }
            Button("Cancel", role: .cancel) { snippetToDelete = nil }
        }
        .tint(VaultStyle.accent)
        .frame(minWidth: 760, minHeight: 520)
    }

    private func historyPanels(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            clipList.frame(width: max(290, width * 0.42))
            Rectangle().fill(VaultStyle.line).frame(width: 1)
            if let item = selectedItem {
                VStack(spacing: 0) {
                    if item.imagePath == nil {
                        HStack {
                            Spacer()
                            Button(item.isSnippet ? "Edit snippet…" : "Save as snippet…") {
                                snippetDraft = SnippetDraft(item: item)
                            }
                        }.padding(.horizontal, 24).padding(.top, 12)
                    }
                    ClipDetailView(item: item, onCopy: { copy(item) },
                                   onPaste: { copy(item, andPaste: true) },
                                   onPin: { togglePin(item) }, onDelete: { delete(item) },
                                   onCopyText: { text in
                                       copy(ClipItem(id: UUID(), timestamp: Date(), content: text, isPinned: false))
                                   })
                        .id(item.id)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(VaultStyle.accent)
                    Text("A little less searching.")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Select a clip to see the whole picture.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var librarySidebar: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack(spacing: 9) {
                VaultMark(size: 30)
                Text("Clippit").font(.system(size: 20, weight: .semibold, design: .rounded))
            }
            .padding(.top, 6)
            VStack(alignment: .leading, spacing: 8) {
                Text("LIBRARY").font(.system(size: 9, weight: .semibold)).tracking(1.4)
                    .foregroundStyle(.secondary).padding(.leading, 10).padding(.bottom, 4)
                ForEach(ClipFilter.allCases) { option in
                    filterButton(option, sidebar: true)
                }
            }
            Spacer(minLength: 20)
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 20, weight: .light)).foregroundStyle(VaultStyle.accent)
                Text("Yours to keep.").font(.system(size: 12, weight: .semibold))
                Text("Your history stays\non this Mac.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineSpacing(3)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(VaultStyle.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
            HStack(spacing: 6) {
                ShortcutBadge(text: settings.historyShortcut.display)
                Text("Quick access").font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .background(VaultStyle.sidebar)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VaultMark(size: 28)
            ForEach(ClipFilter.allCases) { option in
                filterButton(option, sidebar: false)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(VaultStyle.sidebar)
    }

    private func filterButton(_ option: ClipFilter, sidebar: Bool) -> some View {
        Button { filter = option } label: {
            HStack(spacing: 8) {
                Image(systemName: option.symbol).frame(width: 15)
                Text(option == .all ? "All clips" : option.rawValue)
                if sidebar { Spacer(minLength: 0) }
                Text("\(count(for: option))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(filter == option ? VaultStyle.accent : Color.secondary)
            }
            .font(.system(size: 12, weight: filter == option ? .semibold : .regular))
            .padding(.horizontal, 10).padding(.vertical, 10)
            .foregroundStyle(filter == option ? VaultStyle.accent : Color.secondary)
            .background(filter == option ? VaultStyle.selection : Color.clear,
                        in: RoundedRectangle(cornerRadius: 9))
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(filter == option ? .isSelected : [])
        .accessibilityLabel("\(option.rawValue), \(count(for: option)) clips")
    }

    private var clipList: some View {
        VStack(spacing: 0) {
            HStack {
                Text(searchText.isEmpty ? (filter == .all ? "Clipboard" : filter.rawValue) : "Search results")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(visibleItems.count)").font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(VaultStyle.sidebar, in: Capsule())
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 6)
            HStack {
                Text(sort.rawValue).font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 18).padding(.bottom, 14)
            List(selection: $selection) {
                ForEach(visibleItems) { item in
                    ClipRowView(item: item, isSelected: selection == item.id) { togglePin(item) }
                        .tag(item.id)
                        .listRowInsets(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .contextMenu {
                            Button("Copy") { copy(item) }
                            Button("Copy and Paste") { copy(item, andPaste: true) }
                            if item.imagePath == nil {
                                Menu("Copy as") {
                                    ForEach(TextTransform.allCases) { transform in
                                        Button(transform.rawValue) {
                                            if let transformed = item.transformed(transform) { copy(transformed) }
                                        }
                                    }
                                }
                            }
                            if item.isSnippet {
                                Button("Edit snippet…") { snippetDraft = SnippetDraft(item: item) }
                            } else {
                                Button(item.isPinned ? "Unpin" : "Pin") { togglePin(item) }
                                if item.imagePath == nil {
                                    Button("Save as snippet…") { snippetDraft = SnippetDraft(item: item) }
                                }
                            }
                            Divider()
                            Button("Delete", role: .destructive) { delete(item) }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onKeyPress(.return) {
                guard let item = selectedItem else { return .ignored }
                copy(item)
                return .handled
            }
            .overlay {
                if visibleItems.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").font(.system(size: 26, weight: .light))
                        Text("No matching clips").font(.system(size: 14, weight: .medium))
                        Text("Try another search or filter.").font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                    .allowsHitTesting(false)
                }
            }
        }
    }

    private var emptyHistory: some View {
        VStack(spacing: 18) {
            VaultMark(size: 64)
                .padding(24)
                .background(VaultStyle.accent.opacity(0.05), in: Circle())
                .overlay(Circle().strokeBorder(VaultStyle.accent.opacity(0.10)))
            VStack(spacing: 10) {
                Text("Clipboard is quiet…").font(.system(size: 25, weight: .semibold, design: .rounded))
                Text("Copy something! Your text, links, and images will appear here.")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
            }
            HStack(spacing: 7) {
                ShortcutBadge(text: settings.historyShortcut.display)
                Text("Bring your clipboard back, from anywhere.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(VaultStyle.line).frame(height: 1)
            HStack(spacing: 7) {
                if copyFeedback.isVisible {
                    Label("Copied", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(VaultStyle.accent)
                        .accessibilityLabel("Copied to clipboard")
                }
                Circle().fill(VaultStyle.accent).frame(width: 5, height: 5)
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let count = store.countToday(now: context.date)
                    Text("\(count) \(count == 1 ? "clip" : "clips") today")
                        .help("Clips from today still in history, using your local time zone.")
                }
                Spacer()
                ShortcutBadge(text: "↵")
                Text("Copy")
                ShortcutBadge(text: "⌘⇧C").padding(.leading, 10)
                Text("Copy & paste")
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
            .padding(.horizontal, 24).padding(.vertical, 11)
        }
    }

    private func copy(_ item: ClipItem, andPaste: Bool = false) {
        copyFeedback.copy { andPaste ? onCopyAndPaste(item) : onCopy(item) }
    }

    private func exportText() {
        let snapshot = visibleItems
        let panel = NSSavePanel()
        panel.title = "Export visible text clips"
        panel.message = "Includes text from the current search and filter. Visible snippets include their names and contents. Images are excluded. The exported file is not encrypted."
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Clippit-text.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try TextHistoryExport.encode(snapshot).write(to: url, options: .atomic) }
        catch { errorMessage = error.localizedDescription }
    }

    private func count(for filter: ClipFilter) -> Int {
        switch filter {
        case .all: return store.items.count
        case .text: return store.items.filter { $0.imagePath == nil }.count
        case .images: return store.items.filter { $0.imagePath != nil }.count
        case .pinned: return store.items.filter(\.isPinned).count
        case .snippets: return store.items.filter(\.isSnippet).count
        }
    }

    private func refreshResults() {
        do { visibleItems = try store.search(searchText, filter: filter, sort: sort) }
        catch { visibleItems = []; errorMessage = error.localizedDescription }
        if !visibleItems.contains(where: { $0.id == selection }) {
            selection = visibleItems.first?.id
        }
    }

    private func togglePin(_ item: ClipItem) {
        do { try store.setPinned(item.id, to: !item.isPinned) }
        catch { errorMessage = error.localizedDescription }
    }

    private func delete(_ item: ClipItem) {
        if item.isSnippet { snippetToDelete = item; return }
        deleteConfirmed(item)
    }

    private func deleteConfirmed(_ item: ClipItem) {
        do { try store.delete(item.id); refreshResults() }
        catch { errorMessage = error.localizedDescription }
    }

    static func relativeTime(_ timestamp: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(timestamp)))
        if seconds < 60 { return "just now" }
        if seconds < 3_600 { return "\(seconds / 60)m ago" }
        if seconds < 86_400 { return "\(seconds / 3_600)h ago" }
        return "\(seconds / 86_400)d ago"
    }
}
