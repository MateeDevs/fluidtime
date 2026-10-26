import ComposableArchitecture
import MenuBarExtraAccess
import SwiftUI

@main
struct FluidtimeApp: App {
    @NSApplicationDelegateAdaptor(FluidtimeAppDelegate.self) private var delegate

    private var store: StoreOf<AppFeature> {
        delegate.store
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            MenuBarLabelView(store: store)
        }
        .menuBarExtraAccess(isPresented: Binding(
            get: { store.isMenuBarPresented },
            set: { store.send(.interface(.menuBarPresentationChanged($0))) }
        ), statusItem: { statusItem in
            TimerFeedbackPanel.shared.anchor(to: statusItem)
        })
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store)
        }
        .defaultSize(width: 540, height: 460)
        .commands {
            WorkspaceCommands()
            CommandGroup(replacing: .newItem) {
                Button(.workspaceOpenWindow) { store.send(.view(.openMainWindow)) }.keyboardShortcut("n")
            }
        }
    }
}
