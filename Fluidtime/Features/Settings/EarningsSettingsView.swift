import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct EarningsSettingsView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        Form {
            Section {
                Toggle(.earningsEnabled, isOn: Binding(
                    get: { store.preferences.workspace.earningsEnabled },
                    set: { enabled in
                        var preferences = store.preferences.workspace
                        preferences.earningsEnabled = enabled
                        send(.workspacePreferencesChanged(preferences))
                    }
                ))
                Text(.earningsEnabledHelp).font(.callout).foregroundStyle(.secondary)
            }
            if store.preferences.workspace.earningsEnabled {
                EarningsRateSettingsView(store: store.scope(state: \.earnings, action: \.earnings))
            }
        }
        .formStyle(.grouped)
    }
}

@ViewAction(for: EarningsFeature.self)
private struct EarningsRateSettingsView: View {
    let store: StoreOf<EarningsFeature>
    @Environment(\.locale) private var locale

    var body: some View {
        Section {
            HStack {
                EarningsPrivacyControls(store: store, surface: .settings)
            }
            if store.surface == .settings, let settings = store.settings {
                TextField(String(localized: .earningsHourlyRate), value: Binding(
                    get: { settings.hourlyRate }, set: { send(.rateChanged($0)) }
                ), format: .number)
                    .disabled(store.operation != nil)
                Picker(.earningsCurrency, selection: Binding(
                    get: { settings.currency }, set: { send(.currencyChanged($0)) }
                )) {
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) { currency in
                        Text(locale.localizedString(forCurrencyCode: currency) ?? currency).tag(currency)
                    }
                }.disabled(store.operation != nil)
                Text(.earningsFixedRateHelp).font(.callout).foregroundStyle(.secondary)
                Button(.earningsSaveRate) { send(.save) }
                    .disabled(!store.hasChanges || store.operation != nil)
                if store.hasChanges {
                    Text(.earningsUnsaved).font(.callout).foregroundStyle(.secondary)
                }
            } else {
                Text(.earningsSettingsPrivacyHelp).font(.callout).foregroundStyle(.secondary)
            }
            if store.accountScope.isEmpty {
                Text(.earningsConnectFirst).font(.callout).foregroundStyle(.secondary)
            }
            if let error = store.error {
                Label(error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.secondary)
            }
        } header: { Text(.workspaceEarnings) }
            .onDisappear { send(.conceal(.settings)) }
    }
}
