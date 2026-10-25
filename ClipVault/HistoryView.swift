// Purpose: Present a refined history browser with SQLite filters, native search, and a full clip preview.
import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: ClipStore
    @ObservedObject var presentation: HistoryPresentation
    let onCopy: (ClipItem) -> Void
    let onCopyAndPaste: (ClipItem) -> Void
    @State private var isSearchPresented = false
    @State private var searchText = ""
    @State private var selection: UUID?
    @State private var errorMessage: String?
    @State private var filter: ClipFilter = .all
    @State private var visibleItems: [ClipItem] = []

    private var selectedItem: ClipItem? { visibleItems.first { $0.id == selection } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Rectangle().fill(VaultStyle.line).frame(height: 1)
                if store.items.isEmpty {
                    emptyHistory
                } else {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            clipList.frame(width: max(330, geometry.size.width * 0.46))
                            Rectangle().fill(VaultStyle.line).frame(width: 1)
                            if let item = selectedItem {
                                ClipDetailView(item: item, onCopy: { onCopy(item) },
                                               onPaste: { onCopyAndPaste(item) },
                                               onPin: { togglePin(item) }, onDelete: { delete(item) })
                                    .id(item.id)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundStyle(VaultStyle.accent.opacity(0.7))
                                    Text("Select a clip to preview it")
                                        .font(.system(size: 13)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
                footer
            }
            .background(VaultStyle.canvas)
            .searchable(text: $searchText, isPresented: $isSearchPresented, placement: .toolbar, prompt: "Search your clipboard")
            .navigationTitle("ClipVault")
            .background {
                HistoryKeyboardShortcuts { action in
                    guard let item = selectedItem else { return false }
                    switch action {
                    case .copy: onCopy(item)
                    case .copyAndPaste: onCopyAndPaste(item)
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
            .onChange(of: filter) { _, _ in refreshResults() }
            .onChange(of: store.items) { _, _ in refreshResults() }
            .alert("Could not update history", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
        .tint(VaultStyle.accent)
        .frame(minWidth: 760, minHeight: 520)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                VaultMark()
                VStack(alignment: .leading, spacing: 3) {
                    Text("ClipVault").font(.system(size: 24, weight: .semibold, design: .rounded))
                    Text("\(store.items.count) saved · \(store.items.filter(\.isPinned).count) pinned")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Label("On this Mac", systemImage: "desktopcomputer")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(VaultStyle.surface, in: Capsule())
                    .overlay(Capsule().strokeBorder(VaultStyle.line))
                    .help("Your clipboard history is stored locally on this Mac.")
            }
            HStack(spacing: 6) {
                ForEach(ClipFilter.allCases) { option in
                    Button { filter = option } label: {
                        HStack(spacing: 7) {
                            Text(option.rawValue)
                            Text("\(count(for: option))")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.primary.opacity(0.055), in: Capsule())
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .foregroundStyle(filter == option ? VaultStyle.accent : Color.secondary)
                        .background(filter == option ? VaultStyle.accent.opacity(0.10) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 9))
                        .contentShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                    .accessibilityLabel("\(option.rawValue), \(count(for: option)) clips")
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 16)
    }

    private var clipList: some View {
        VStack(spacing: 0) {
            HStack {
                Text(searchText.isEmpty ? "RECENT CLIPS" : "SEARCH RESULTS")
                    .font(.system(size: 10, weight: .semibold)).tracking(1.5)
                Spacer()
                Text("\(visibleItems.count)").font(.system(size: 11, design: .rounded))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 12)
            List(selection: $selection) {
                ForEach(visibleItems) { item in
                    ClipRowView(item: item, isSelected: selection == item.id) { togglePin(item) }
                        .tag(item.id)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .contextMenu {
                            Button("Copy") { onCopy(item) }
                            Button("Copy and Paste") { onCopyAndPaste(item) }
                            if item.imagePath == nil {
                                Menu("Copy as") {
                                    ForEach(TextTransform.allCases) { transform in
                                        Button(transform.rawValue) {
                                            if let copy = item.transformed(transform) { onCopy(copy) }
                                        }
                                    }
                                }
                            }
                            Button(item.isPinned ? "Unpin" : "Pin") { togglePin(item) }
                            Divider()
                            Button("Delete", role: .destructive) { delete(item) }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onKeyPress(.return) {
                guard let item = selectedItem else { return .ignored }
                onCopy(item)
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
                ShortcutBadge(text: "⌘⇧V")
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

    private func count(for filter: ClipFilter) -> Int {
        switch filter {
        case .all: return store.items.count
        case .text: return store.items.filter { $0.imagePath == nil }.count
        case .images: return store.items.filter { $0.imagePath != nil }.count
        case .pinned: return store.items.filter(\.isPinned).count
        }
    }

    private func refreshResults() {
        do { visibleItems = try store.search(searchText, filter: filter) }
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
