// Purpose: Display a bounded 40-point image preview with a missing-file fallback.
import SwiftUI

struct ClipThumbnail: View {
    let path: String
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .help("Image preview unavailable")
            }
        }
        .frame(width: 40, height: 40)
        .accessibilityLabel("Clipboard image")
        .task(id: path) {
            image = ClipImages.thumbnail(at: path)
        }
    }
}
