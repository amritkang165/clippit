// Purpose: Create and edit local named text snippets without modifying the source clip.
import SwiftUI

struct SnippetDraft: Identifiable {
    let id = UUID()
    var existingID: UUID?
    var title = ""
    var text = ""
    init(item: ClipItem? = nil) {
        existingID = item?.isSnippet == true ? item?.id : nil
        title = item?.snippetTitle ?? ""
        text = item?.content ?? ""
    }
}

struct SnippetEditor: View {
    let draft: SnippetDraft
    let save: (String, String) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var text = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(draft.existingID == nil ? "New snippet" : "Edit snippet").font(.title2)
            TextField("Name", text: $title)
            TextEditor(text: $text).font(.body).frame(minHeight: 180)
                .accessibilityLabel("Snippet text")
            Text("Saved on this Mac. History limits and Clear history do not remove snippets.")
                .font(.caption).foregroundStyle(.secondary)
            if let error { Text(error).foregroundStyle(.red) }
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    do { try save(title, text); dismiss() }
                    catch { self.error = error.localizedDescription }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.padding(24).frame(width: 480)
            .background(Color(nsColor: .windowBackgroundColor))
            .onAppear { title = draft.title; text = draft.text }
    }
}
