// Purpose: Preview the selected clip and expose copy, paste, pin, and delete actions.
import SwiftUI

struct ClipDetailView: View {
    let item: ClipItem
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    @State private var previewImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PREVIEW").font(.system(size: 10, weight: .semibold)).tracking(1.6)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onPin) {
                    Label(item.isPinned ? "Pinned" : "Pin clip", systemImage: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .tint(VaultStyle.accent)
                .help(item.isPinned ? "Unpin clip" : "Pin clip")
            }

            VStack(alignment: .leading, spacing: 7) {
                Label(item.kind.label, systemImage: item.kind.symbol)
                    .font(.system(size: 24, weight: .semibold))
                Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }

            Group {
                if item.imagePath != nil {
                    if let previewImage {
                        Image(nsImage: previewImage)
                            .resizable().scaledToFit()
                            .padding(16)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel("Selected clipboard image")
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "photo").font(.largeTitle)
                            Text("Image preview unavailable").font(.callout)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ScrollView {
                        Text(verbatim: item.content)
                            .font(.system(size: 14))
                            .lineSpacing(6)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(VaultStyle.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(VaultStyle.line))

            HStack {
                Text(item.imagePath == nil ? "\(item.content.count.formatted()) characters" : "PNG image")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help("Delete clip")
                .accessibilityLabel("Delete clip")
            }

            HStack(spacing: 10) {
                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(VaultActionButtonStyle(primary: true))
                .help("Copy clip (⌘C)")
                Button(action: onPaste) {
                    Label("Copy & Paste", systemImage: "arrow.up.forward")
                }
                .buttonStyle(VaultActionButtonStyle())
                .help("Copy and paste into your previous app (⌘⇧C)")
            }
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: item.imagePath) {
            previewImage = nil
            if let path = item.imagePath {
                previewImage = ClipImages.thumbnail(at: path, maxPixelSize: 800)
            }
        }
    }
}
