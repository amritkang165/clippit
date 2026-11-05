// Purpose: Present a readable clip card with type, thumbnail, relative time, and a pin control.
import SwiftUI

struct ClipRowView: View {
    let item: ClipItem
    let isSelected: Bool
    let onPin: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let path = item.imagePath {
                    ClipThumbnail(path: path)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: item.kind.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(item.kind.tint)
                        .frame(width: 40, height: 40)
                        .background(item.kind.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 11))
                }
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(verbatim: item.rowPreview)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 6) {
                    Text(item.kind.label)
                    Text("·")
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        Text(HistoryView.relativeTime(item.timestamp, now: context.date))
                    }
                    if item.isPinned {
                        Text("·")
                        Text("Pinned").foregroundStyle(VaultStyle.accent)
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            }
            Button(action: onPin) {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(item.isPinned ? VaultStyle.accent : Color.secondary)
                    .frame(width: 28, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(item.isPinned || isHovered || isSelected ? 1 : 0.45)
            .help(item.isPinned ? "Unpin clip" : "Pin clip")
            .accessibilityLabel(item.isPinned ? "Unpin clip" : "Pin clip")
        }
        .padding(12)
        .frame(minHeight: 76)
        .background(isSelected ? VaultStyle.accent.opacity(0.12) : VaultStyle.surface,
                    in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13)
            .strokeBorder(isSelected ? VaultStyle.accent.opacity(0.34) : VaultStyle.line, lineWidth: 1))
        .background(CardListSelectionStyle().frame(width: 0, height: 0))
        .contentShape(RoundedRectangle(cornerRadius: 13))
        .onHover { isHovered = $0 }
    }
}
