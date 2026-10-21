// Purpose: Present history preferences and the system-backed launch-at-login control.
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var loginItem: LoginItemStore
    @State private var errorMessage: String?
    @State private var maxItemsInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                VaultMark(size: 42)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Make it yours").font(.system(size: 23, weight: .semibold, design: .rounded))
                    Text("History and startup preferences")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            .padding(24)
            Rectangle().fill(VaultStyle.line).frame(height: 1)
            Form {
                Section("Startup") {
                    Toggle("Launch at login", isOn: Binding(
                        get: { loginItem.isRequested },
                        set: { enabled in
                            do { try loginItem.setEnabled(enabled) }
                            catch { errorMessage = error.localizedDescription }
                        }
                    ))
                    .disabled(!loginItem.isAppBundle)
                    if !loginItem.isAppBundle {
                        Text("Install ClipVault.app in Applications to enable launch at login.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else if loginItem.status == .requiresApproval {
                        Text("Approval is needed in Login Items before ClipVault can launch automatically.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Open Login Items…") { loginItem.openSystemSettings() }
                    } else if loginItem.status == .notFound {
                        Text("macOS could not locate the login item. Open the installed, signed app and try again.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("History") {
                    HStack {
                        TextField("Maximum clips", text: $maxItemsInput)
                            .onSubmit { applyHistoryLimit() }
                        Button("Apply") { applyHistoryLimit() }
                            .disabled(Int(maxItemsInput) == settings.maxItems)
                    }
                    Text("Pinned clips are kept even when they exceed this limit.")
                        .font(.caption).foregroundStyle(.secondary)
                    Toggle("Ignore password copies", isOn: $settings.ignorePasswords)
                    Text("Skips identifiable password-manager copies and confidential clipboard content. Detection is best-effort.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .background(VaultStyle.canvas)
        .tint(VaultStyle.accent)
        .frame(width: 500, height: 520)
        .onAppear {
            loginItem.refresh()
            maxItemsInput = String(settings.maxItems)
        }
        .onChange(of: settings.maxItems) { _, value in maxItemsInput = String(value) }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginItem.refresh()
        }
        .alert("Could not update settings", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func applyHistoryLimit() {
        guard let value = Int(maxItemsInput), value > 0 else {
            errorMessage = "Enter a whole number of at least 1 for Maximum clips."
            return
        }
        settings.maxItems = value
    }
}
