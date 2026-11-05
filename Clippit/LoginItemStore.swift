// Purpose: Manage opt-in launch at login through SMAppService and report its actual system status.
import Foundation
import Combine
import ServiceManagement

@MainActor
protocol LoginItemServicing {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

@MainActor
private struct SystemLoginItemService: LoginItemServicing {
    var status: SMAppService.Status { SMAppService.mainApp.status }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
}

@MainActor
final class LoginItemStore: ObservableObject {
    @Published private(set) var status: SMAppService.Status
    let isAppBundle: Bool
    private let service: LoginItemServicing

    init(service: LoginItemServicing? = nil,
         isAppBundle: Bool = Bundle.main.bundleURL.pathExtension == "app") {
        let service = service ?? SystemLoginItemService()
        self.service = service
        self.isAppBundle = isAppBundle
        status = service.status
    }

    var isRequested: Bool { status == .enabled || status == .requiresApproval }

    func refresh() { status = service.status }

    func setEnabled(_ enabled: Bool) throws {
        guard isAppBundle else { throw LoginItemError.appBundleRequired }
        refresh()
        defer { refresh() }
        if enabled && !isRequested { try service.register() }
        else if !enabled && isRequested { try service.unregister() }
    }

    func openSystemSettings() { SMAppService.openSystemSettingsLoginItems() }
}

private enum LoginItemError: LocalizedError {
    case appBundleRequired
    var errorDescription: String? {
        "Launch at login requires the signed Clippit.app. Install it in Applications and open it there."
    }
}
