import ComposableArchitecture
@testable import FluidtimeCore
import SwiftUI

/// Mirrors the app's Settings container so each existing tab can be seeded without real input.
struct ReviewSettingsTabs: View {
    @Bindable var store: StoreOf<AppFeature>
    let selection: Int

    var body: some View {
        TabView(selection: .constant(selection)) {
            GeneralSettingsView(
                store: store.scope(state: \.generalSettings, action: \.generalSettings)
            )
            .tabItem { Label(.general, systemImage: "gearshape") }.tag(3)
            TrackingSettingsView(store: store)
                .tabItem { Label(.tracking, systemImage: "timer") }.tag(1)
            WorkspaceSettingsView(store: store)
                .tabItem { Label(.settingsWorkspace, systemImage: "macwindow") }.tag(4)
            EarningsSettingsView(store: store)
                .tabItem { Label(.workspaceEarnings, systemImage: "banknote") }.tag(5)
            MenuBarSettingsView(store: store)
                .tabItem { Label(.menuBar, systemImage: "menubar.rectangle") }.tag(2)
            AccountSettingsView(store: store)
                .tabItem { Label(.account, systemImage: "person.crop.circle") }.tag(0)
        }
        .frame(width: 540, height: 460)
        .confirmationDialog($store.scope(state: \.destination?.disconnect, action: \.destination.disconnect))
    }
}
