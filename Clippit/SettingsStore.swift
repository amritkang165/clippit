// Purpose: Persist history limits and password filtering preferences in UserDefaults.
import Foundation
import Combine

final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults
    var onMaxItemsChange: ((Int) -> Void)?

    var onCapturePauseChange: (() -> Void)?
    var onShortcutChange: ((HistoryShortcut) throws -> Void)?
    @Published private(set) var historyShortcut: HistoryShortcut
    @Published var shortcutError: String?

    func setHistoryShortcut(_ value: HistoryShortcut) throws {
        guard value.isValid else { throw ShortcutError.invalid }
        try onShortcutChange?(value)
        defaults.set(try JSONEncoder().encode(value), forKey: "historyShortcut")
        historyShortcut = value
        shortcutError = nil
    }

    @Published var maxTextCharacters: Int {
        didSet {
            if maxTextCharacters < 0 { maxTextCharacters = 0 }
            defaults.set(maxTextCharacters, forKey: "maxTextCharacters")
        }
    }

    @Published var capturePaused: Bool {
        didSet {
            defaults.set(capturePaused, forKey: "capturePaused")
            onCapturePauseChange?()
        }
    }

    @Published var maxItems: Int {
        didSet {
            if maxItems < 1 { maxItems = 1 }
            defaults.set(maxItems, forKey: "maxItems")
            onMaxItemsChange?(maxItems)
        }
    }

    @Published var ignorePasswords: Bool {
        didSet { defaults.set(ignorePasswords, forKey: "ignorePasswords") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.data(forKey: "historyShortcut").flatMap { try? JSONDecoder().decode(HistoryShortcut.self, from: $0) }
        historyShortcut = saved?.isValid == true ? saved! : .default
        defaults.register(defaults: ["maxItems": 500, "ignorePasswords": true])
        maxTextCharacters = max(0, defaults.integer(forKey: "maxTextCharacters"))
        capturePaused = defaults.bool(forKey: "capturePaused")
        maxItems = max(1, defaults.integer(forKey: "maxItems"))
        ignorePasswords = defaults.bool(forKey: "ignorePasswords")
    }
}
