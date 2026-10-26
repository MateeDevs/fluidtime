import ComposableArchitecture
import KeyboardShortcuts
import SwiftUI

@ViewAction(for: AppFeature.self)
struct MenuBarSettingsView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Form {
            Section(.menuBar) {
                Picker(.display, selection: Binding(
                    get: { store.menuBarDisplay == .indicator ? .clock : store.menuBarDisplay },
                    set: { send(.binding(.set(\.menuBarDisplay, $0))) }
                )) {
                    Text(.runningTimer).tag(MenuBarDisplay.elapsed)
                    Text(.todaysTotal).tag(MenuBarDisplay.today)
                    Text(.thisWeeksTotal).tag(MenuBarDisplay.week)
                    Text(.clockOnly).tag(MenuBarDisplay.clock)
                }
                Toggle(.showSeconds, isOn: $store.menuBarShowsSeconds)
                    .disabled(store.menuBarDisplay == .indicator || store.menuBarDisplay == .clock)
                Toggle(.menuBarProjectColor, isOn: $store.menuBarUsesProjectColor)
                Text(.menuBarTotalsHelp)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section(.keyboardShortcut) {
                VStack(alignment: .leading, spacing: 8) {
                    KeyboardShortcuts.Recorder(String(localized: .showOrHideFluidtime), name: .openFluidtime)
                        .keyboardShortcutsConflictPolicy(.init(systemShortcut: .block))
                    Text(.showOrHideTheMenuEvenWhenAnotherAppIsActive)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    KeyboardShortcuts.Recorder(String(localized: .shortcutToggleTimer), name: .toggleFluidtimeTimer)
                        .keyboardShortcutsConflictPolicy(.init(systemShortcut: .block))
                    Text(.shortcutTimerHelp).font(.callout).foregroundStyle(.secondary)
                }
                Button(.restoreDefault) {
                    KeyboardShortcuts.reset(.openFluidtime)
                    KeyboardShortcuts.reset(.toggleFluidtimeTimer)
                }
            }
        }
        .formStyle(.grouped)
    }
}
