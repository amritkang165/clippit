// Purpose: Confirm successful clipboard writes without promising that simulated paste succeeded.
import AppKit
import Combine

@MainActor
final class CopyFeedback: ObservableObject {
    @Published private(set) var isVisible = false
    private var dismissal: Task<Void, Never>?
    private var generation = 0
    private let duration: UInt64
    private let announce: @MainActor () -> Void

    init(duration: UInt64 = 2_000_000_000, announce: @escaping @MainActor () -> Void = {
        NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested,
                             userInfo: [.announcement: "Copied", .priority: NSAccessibilityPriorityLevel.medium.rawValue])
    }) {
        self.duration = duration
        self.announce = announce
    }

    func copy(using operation: () -> Bool) {
        dismissal?.cancel()
        generation += 1
        isVisible = false
        guard operation() else { return }
        isVisible = true
        announce()
        let current = generation
        dismissal = Task { [weak self, duration] in
            do { try await Task.sleep(nanoseconds: duration) } catch { return }
            guard let self, generation == current else { return }
            isVisible = false
        }
    }

    deinit { dismissal?.cancel() }
}
