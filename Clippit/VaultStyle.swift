// Purpose: Define the adaptive visual theme, controls, and presentation-only clip labels.
import SwiftUI

enum VaultStyle {
    static let accent = adaptive(light: (0.10, 0.43, 0.37), dark: (0.43, 0.82, 0.69))
    static let onAccent = adaptive(light: (1, 1, 1), dark: (0.05, 0.14, 0.12))
    static let canvas = adaptive(light: (0.975, 0.978, 0.98), dark: (0.085, 0.095, 0.105))
    static let sidebar = adaptive(light: (0.935, 0.95, 0.95), dark: (0.105, 0.12, 0.13))
    static let selection = adaptive(light: (0.85, 0.93, 0.90), dark: (0.13, 0.24, 0.22))
    static let surface = adaptive(light: (1, 1, 0.99), dark: (0.125, 0.14, 0.15))
    static let line = Color.primary.opacity(0.08)

    private static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let rgb = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }
}

enum ClipKind {
    case text, link, image
    var label: String {
        switch self { case .text: return "Text"; case .link: return "Link"; case .image: return "Image" }
    }
    var symbol: String {
        switch self { case .text: return "text.alignleft"; case .link: return "link"; case .image: return "photo" }
    }
    var tint: Color {
        switch self { case .text: return VaultStyle.accent; case .link: return .blue; case .image: return .purple }
    }
}

extension ClipItem {
    var kind: ClipKind {
        if imagePath != nil { return .image }
        let value = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.contains(where: { $0.isWhitespace }),
           let url = URLComponents(string: value), let host = url.host, !host.isEmpty,
           ["http", "https"].contains(url.scheme?.lowercased() ?? "") { return .link }
        return .text
    }

    var rowPreview: String {
        if let snippetTitle { return snippetTitle }
        if imagePath != nil { return "Copied image" }
        let value = String(content.prefix(80)).components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.joined(separator: " ")
        return value.isEmpty ? "Empty text" : value + (content.count > 80 ? "…" : "")
    }
}

struct VaultMark: View {
    var size: CGFloat = 40
    var body: some View {
        Image(systemName: "clipboard")
            .font(.system(size: size * 0.46, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [Color(red: 0.18, green: 0.53, blue: 0.46),
                                               Color(red: 0.07, green: 0.27, blue: 0.27)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: size * 0.27))
            .overlay(RoundedRectangle(cornerRadius: size * 0.27).strokeBorder(.white.opacity(0.15)))
            .accessibilityHidden(true)
    }
}

struct ShortcutBadge: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5).padding(.vertical, 3)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(VaultStyle.line))
    }
}

struct VaultActionButtonStyle: ButtonStyle {
    var primary = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(primary ? VaultStyle.onAccent : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(primary ? VaultStyle.accent : VaultStyle.surface,
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .strokeBorder(primary ? Color.clear : VaultStyle.line))
            .opacity(!isEnabled ? 0.45 : (configuration.isPressed ? 0.8 : 1))
    }
}
