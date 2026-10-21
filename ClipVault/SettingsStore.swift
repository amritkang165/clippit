// Purpose: Persist history limits and password filtering preferences in UserDefaults.
import Foundation
import Combine

final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults
    var onMaxItemsChange: ((Int) -> Void)?

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
        defaults.register(defaults: ["maxItems": 500, "ignorePasswords": true])
        maxItems = max(1, defaults.integer(forKey: "maxItems"))
        ignorePasswords = defaults.bool(forKey: "ignorePasswords")
    }
}
