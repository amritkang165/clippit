// Purpose: Preview the selected clip and expose copy, paste, pin, and delete actions.
import SwiftUI

struct ClipDetailView: View {
    let item: ClipItem
    let onCopy: () -> Void
    let onPaste: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onCopyText: (String) -> Void
    @State private var previewImage: NSImage?
    @State private var recognitionAttempt = 0
    @State private var isRecognizing = false
    @State private var recognizedText: String?
    @State private var recognitionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SELECTED CLIP").font(.system(size: 10, weight: .semibold)).tracking(1.3)
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

            HStack(spacing: 12) {
                Image(systemName: item.kind.symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(item.kind.tint)
                    .frame(width: 44, height: 44)
                    .background(item.kind.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.kind == .image ? "Image clip" : item.kind == .link ? "Saved link" : "Text clip")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }

            Group {
                if item.imagePath != nil {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let previewImage {
                                Image(nsImage: previewImage)
                                    .resizable().scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .accessibilityLabel("Selected clipboard image")
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "photo").font(.largeTitle)
                                    Text("Image preview unavailable").font(.callout)
                                }
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity).frame(height: 120)
                            }
                            imageTextControls
                        }
                        .padding(16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(verbatim: item.content)
                            .font(.system(size: 14))
                            .lineSpacing(6)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(22)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(VaultStyle.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VaultStyle.line))

            HStack {
                Text(item.imagePath == nil ? "\(item.content.count.formatted()) characters" : "PNG image")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").foregroundStyle(.secondary).frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("Delete clip")
                .accessibilityLabel("Delete clip")
            }

            HStack(spacing: 10) {
                Button(action: onCopy) {
                    HStack {
                        Label("Copy", systemImage: "doc.on.doc")
                        Spacer()
                        Text("↵").opacity(0.65)
                    }.padding(.horizontal, 14)
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
        .task(id: recognitionAttempt) {
            guard recognitionAttempt > 0, let path = item.imagePath else { return }
            do {
                let text = try await ImageTextRecognizer.shared.recognize(at: URL(fileURLWithPath: path))
                try Task.checkCancellation()
                recognizedText = text
                isRecognizing = false
            } catch is CancellationError {
                // The selected clip or window changed; do not apply an obsolete result.
            } catch {
                guard !Task.isCancelled else { return }
                recognitionError = error.localizedDescription
                isRecognizing = false
            }
        }
    }

    private var imageTextControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Text from image", systemImage: "text.viewfinder")
                .font(.system(size: 12, weight: .semibold))
            Text("Read and copy text, right on your Mac.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            HStack {
                Button {
                    recognizedText = nil
                    recognitionError = nil
                    isRecognizing = true
                    recognitionAttempt += 1
                } label: {
                    Label(recognizedText == nil ? "Recognize Text" : "Scan Again",
                          systemImage: "text.viewfinder")
                }
                .disabled(isRecognizing)
                .help("Recognize text on this Mac using Apple Vision.")
                if isRecognizing {
                    ProgressView().controlSize(.small)
                    Text("Reading image…").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let text = recognizedText, !text.isEmpty {
                    Button("Copy Text") { onCopyText(text) }
                }
            }
            if let error = recognitionError {
                Text(error).font(.caption).foregroundStyle(.red)
            } else if let text = recognizedText {
                if text.isEmpty {
                    Text("No readable text found. Try a clearer image.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        Text(verbatim: text)
                            .font(.system(size: 13)).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    }
                    .frame(height: 120)
                    .background(VaultStyle.surface, in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Recognized image text")
                }
            }
        }
        .padding(14)
        .background(VaultStyle.sidebar.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
    }
}
