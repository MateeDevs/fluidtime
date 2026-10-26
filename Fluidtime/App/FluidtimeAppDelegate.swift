import AppKit
import ComposableArchitecture
import KeyboardShortcuts

/// Synchronization follows the application lifetime, including while the menu panel is closed.
@MainActor
final class FluidtimeAppDelegate: NSObject, NSApplicationDelegate {
    let store: StoreOf<AppFeature>

    @Dependency(\.updates) private var updates
    private var didStart = false
    private var isLoginItem = false

    override init() {
        store = Store(initialState: AppFeature.State()) { AppFeature() }
        super.init()
    }

    func applicationDidFinishLaunching(_: Notification) {
        isLoginItem = ApplicationLaunch.isLoginItem(NSAppleEventManager.shared().currentAppleEvent)
        AppWindows.shared.configure(store: store)
        for name in [NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.willSleepNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(
                self, selector: #selector(lockEarnings), name: name, object: nil
            )
        }
        beginStartup()
    }

    private func beginStartup() {
        guard !didStart else { return }
        didStart = true
        if UpdatesConfiguration.isEnabled {
            updates.start()
        }
        KeyboardShortcuts.onKeyUp(for: .openFluidtime) { [weak self] in
            self?.store.send(.interface(.toggleMenuBar))
        }
        KeyboardShortcuts.onKeyUp(for: .toggleFluidtimeTimer) { [weak self] in
            self?.store.send(.interface(.toggleTimer))
        }
        store.send(.interface(.start))
        if !isLoginItem {
            store.send(.interface(.openPrimaryInterface))
        }
    }

    func applicationWillTerminate(_: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        if didStart {
            KeyboardShortcuts.removeHandler(for: .openFluidtime)
            KeyboardShortcuts.removeHandler(for: .toggleFluidtimeTimer)
        }
        store.send(.interface(.shutdown))
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        guard didStart else {
            isLoginItem = false
            beginStartup()
            return false
        }
        store.send(.interface(.openPrimaryInterface))
        return true
    }

    @objc private func lockEarnings(_: Notification) {
        store.send(.earnings(.interface(.lock)))
    }
}
