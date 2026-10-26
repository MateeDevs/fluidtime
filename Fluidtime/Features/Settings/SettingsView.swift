import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct SettingsView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        TabView {
            GeneralSettingsView(
                store: store.scope(state: \.generalSettings, action: \.generalSettings)
            )
            .tabItem { Label(.general, systemImage: "gearshape") }
            TrackingSettingsView(store: store)
                .tabItem { Label(.tracking, systemImage: "timer") }
            WorkspaceSettingsView(store: store)
                .tabItem { Label(.settingsWorkspace, systemImage: "macwindow") }
            EarningsSettingsView(store: store)
                .tabItem { Label(.workspaceEarnings, systemImage: "banknote") }
            MenuBarSettingsView(store: store)
                .tabItem { Label(.menuBar, systemImage: "menubar.rectangle") }
            AccountSettingsView(store: store)
                .tabItem { Label(.account, systemImage: "person.crop.circle") }
        }
        .frame(width: 540, height: 460)
        .background {
            SettingsWindowObserver(store: store)
        }
        .confirmationDialog($store.scope(state: \.destination?.disconnect, action: \.destination.disconnect))
    }
}
