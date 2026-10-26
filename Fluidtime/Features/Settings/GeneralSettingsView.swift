import ComposableArchitecture
import SwiftUI

@ViewAction(for: GeneralSettingsFeature.self)
struct GeneralSettingsView: View {
    let store: StoreOf<GeneralSettingsFeature>

    var body: some View {
        Form {
            Section(.startup) {
                HStack {
                    Toggle(.launchAtLogin, isOn: Binding(
                        get: { store.launchAtLogin },
                        set: { send(.launchAtLoginChanged($0)) }
                    ))
                    .disabled(store.status == nil || store.status == .unavailable || store.isUpdating)
                    if store.showsProgress {
                        ProgressView().controlSize(.small).accessibilityLabel(.updatingLaunchAtLogin)
                    }
                }
                Text(.openFluidtimeAutomaticallyWhenYouLogInToYourMac)
                    .font(.callout).foregroundStyle(.secondary)
                if store.status == .requiresApproval {
                    Text(.loginItemApprovalHelp).font(.callout).foregroundStyle(.secondary)
                    Button(.openLoginItemsSettings) { send(.openLoginItemsSettingsTapped) }
                } else if store.status == .unavailable {
                    Text(.loginItemUnavailable).font(.callout).foregroundStyle(.secondary)
                }
                if let error = store.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Section {
                Text(.fluidtimeKeepsRunningWhenYouCloseThisWindow)
                    .font(.callout).foregroundStyle(.secondary)
            }
            UpdatesSettingsSection(store: store.scope(state: \.updates, action: \.updates))
        }
        .formStyle(.grouped)
        .task { await send(.appeared).finish() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            send(.applicationBecameActive)
        }
    }
}
