import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct AccountSettingsView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Form {
            Section {
                TextField(
                    .instanceAddress, text: $store.instanceAddress,
                    prompt: Text(.httpsAppSolidtimeIo)
                )
                .autocorrectionDisabled()
                .disabled(!store.canChangeAccount)
                SecureField(.apiKey, text: $store.apiKey, prompt: Text(.enterYourApiKey))
                    .autocorrectionDisabled()
                    .disabled(!store.canChangeAccount)
                Text(.createAnApiKeyInYourSolidtimeAccountSettingsYourKeyIsStoredSecurelyInKeychain)
                    .font(.callout).foregroundStyle(.secondary)
                HStack {
                    Button(store.isConnected ? .updateConnection : .connect) {
                        send(.connectTapped)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        store.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !store.canChangeAccount
                    )
                    if store.showsProgress {
                        ProgressView().controlSize(.small)
                    }
                    Spacer()
                    if store.isConfigured {
                        Button(.disconnect, role: .destructive) { send(.disconnectTapped) }
                            .disabled(!store.canChangeAccount)
                    }
                }
                if let user = store.user {
                    Label(.connectedAs(user.name), systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
                if let error = store.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text(.solidtimeAccount)
            }

            Section {
                Button {
                    send(.openInstanceTapped)
                } label: {
                    Label(.openSolidtime, systemImage: "arrow.up.right.square")
                }
            }
        }
        .formStyle(.grouped)
    }
}
