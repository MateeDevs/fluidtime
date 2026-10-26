import ComposableArchitecture
@testable import FluidtimeCore
import Testing

extension AppFeatureTests {
    @Test func `closing the main window conceals authenticated preview values`() async {
        var initial = state
        initial.isMainWindowOpen = true
        initial.earnings.surface = .preview
        initial.earnings.settings = EarningsSettings(currency: "USD", hourlyRate: 25)
        initial.earnings.savedSettings = initial.earnings.settings
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.system.setDockIconVisible = { _ in }
        }
        await store.send(.interface(.mainWindowOpenChanged(false))) { $0.isMainWindowOpen = false }
        await store.receive(.earnings(.interface(.conceal(.preview)))) {
            $0.earnings = EarningsFeature.State(accountScope: $0.accountScope)
        }
        await store.finish()
    }

    @Test func `dock icon follows settings closing and reopening`() async {
        let visibility = LockIsolated<[Bool]>([])
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.system.setDockIconVisible = { isVisible in visibility.withValue { $0.append(isVisible) } }
        }

        await store.send(.interface(.settingsWindowOpenChanged(true))) { $0.isSettingsWindowOpen = true }
        await store.finish()
        await store.send(.interface(.settingsWindowOpenChanged(true)))
        await store.send(.interface(.settingsWindowOpenChanged(false))) { $0.isSettingsWindowOpen = false }
        await store.finish()
        await store.send(.interface(.settingsWindowOpenChanged(true))) { $0.isSettingsWindowOpen = true }
        await store.finish()

        #expect(visibility.value == [true, false, true])
    }

    @Test func `global shortcut toggles panel without changing the running timer`() async {
        var initial = state
        initial.data.active = entry()
        let store = TestStore(initialState: initial) { AppFeature() }

        await store.send(.interface(.toggleMenuBar)) { $0.isMenuBarPresented = true }
        await store.send(.interface(.toggleMenuBar)) { $0.isMenuBarPresented = false }
        await store.send(.interface(.toggleMenuBar)) { $0.isMenuBarPresented = true }
        await store.send(.interface(.menuBarPresentationChanged(false))) { $0.isMenuBarPresented = false }
        await store.send(.interface(.toggleMenuBar)) { $0.isMenuBarPresented = true }
        await store.finish()
    }

    @Test func `presentation feedback tracks clicks and closes on shutdown`() async {
        let store = TestStore(initialState: state) { AppFeature() }

        await store.send(.interface(.menuBarPresentationChanged(true))) { $0.isMenuBarPresented = true }
        await store.send(.interface(.shutdown)) { $0.isMenuBarPresented = false }
        await store.finish()
    }

    @Test func `project color setting persists without changing the display mode`() async {
        let saved = LockIsolated<Bool?>(nil)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.preferences.setMenuBarUsesProjectColor = { saved.setValue($0) }
        }
        await store.send(.view(.binding(.set(\.menuBarUsesProjectColor, true)))) {
            $0.menuBarUsesProjectColor = true
        }
        await store.finish()
        #expect(saved.value == true)
    }
}
