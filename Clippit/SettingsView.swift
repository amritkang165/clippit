// Purpose: Present history preferences and the system-backed launch-at-login control.
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var loginItem: LoginItemStore
    @State private var errorMessage: String?
    @State private var maxItemsInput = ""
    @State private var maxTextInput = ""

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
                        Text("Install Clippit.app in Applications to enable launch at login.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else if loginItem.status == .requiresApproval {
                        Text("Approval is needed in Login Items before Clippit can launch automatically.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Open Login Items…") { loginItem.openSystemSettings() }
                    } else if loginItem.status == .notFound {
                        Text("macOS could not locate the login item. Open the installed, signed app and try again.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Capture") {
                    HStack {
                        TextField("Maximum text characters", text: $maxTextInput)
                            .onSubmit { applyTextLimit() }
                        Button("Apply") { applyTextLimit() }
                            .disabled(Int(maxTextInput) == settings.maxTextCharacters)
                    }
                    Text("0 means unlimited. Longer copies are skipped, not truncated.")
                        .font(.caption).foregroundStyle(.secondary)
                    Toggle("Pause clipboard capture", isOn: $settings.capturePaused)
                    Text("Saved clips remain available. Copies made while paused are not imported when you resume.")
                        .font(.caption).foregroundStyle(.secondary)
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
            maxTextInput = String(settings.maxTextCharacters)
        }
        .onChange(of: settings.maxTextCharacters) { _, value in maxTextInput = String(value) }
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

    private func applyTextLimit() {
        guard let value = Int(maxTextInput), value >= 0 else {
            errorMessage = "Enter a whole number of 0 or more for Maximum text characters."
            return
        }
        settings.maxTextCharacters = value
    }

    private func applyHistoryLimit() {
        guard let value = Int(maxItemsInput), value > 0 else {
            errorMessage = "Enter a whole number of at least 1 for Maximum clips."
            return
        }
        settings.maxItems = value
    }
}
