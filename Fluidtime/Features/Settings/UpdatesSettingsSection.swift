import ComposableArchitecture
import SwiftUI

@ViewAction(for: UpdatesFeature.self)
struct UpdatesSettingsSection: View {
    let store: StoreOf<UpdatesFeature>

    var body: some View {
        Section(.updatesTitle) {
            if store.status.isAvailable {
                Toggle(.updatesAutomaticChecks, isOn: Binding(
                    get: { store.status.automaticallyChecks }, set: { send(.automaticChecksChanged($0)) }
                ))
                .disabled(!store.status.isAvailable)
                Toggle(.updatesAutomaticInstallation, isOn: Binding(
                    get: { store.status.automaticallyInstalls }, set: { send(.automaticInstallationChanged($0)) }
                ))
                .disabled(!store.status.isAvailable || !store.status.automaticallyChecks)
                Button(.updatesCheckNow) { send(.check) }.disabled(!store.status.canCheck)
                Text(.updatesHelp)
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                Text(.updatesUnavailable).font(.callout).foregroundStyle(.secondary)
                Button(.updatesOpenReleases) { send(.openReleases) }
            }
        }
        .task { await send(.watch).finish() }
    }
}
