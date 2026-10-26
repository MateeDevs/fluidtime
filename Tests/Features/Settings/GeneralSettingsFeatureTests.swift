import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

@MainActor
@Suite(.serialized)
struct GeneralSettingsFeatureTests {
    @Test func `appearance reads system registration without changing it`() async {
        let store = TestStore(initialState: GeneralSettingsFeature.State()) { GeneralSettingsFeature() }
            withDependencies: {
                $0.loginItem.status = { .enabled }
            }
        await store.send(.view(.appeared))
        await store.receive(.statusReceived(.enabled)) { $0.status = .enabled }
        await store.finish()
    }

    @Test(arguments: [false, true])
    func `toggle updates registration and uses confirmed system status`(enabled: Bool) async {
        let initial: LaunchAtLoginStatus = enabled ? .disabled : .enabled
        let confirmed: LaunchAtLoginStatus = enabled ? .enabled : .disabled
        let registration = LockIsolated(initial)
        let store = TestStore(initialState: GeneralSettingsFeature.State(status: initial)) {
            GeneralSettingsFeature()
        } withDependencies: {
            $0.continuousClock = TestClock()
            $0.loginItem.setEnabled = { requested in
                #expect(requested == enabled)
                registration.setValue(confirmed)
            }
            $0.loginItem.status = { registration.value }
        }
        await store.send(.view(.launchAtLoginChanged(enabled))) { $0.requestedEnabled = enabled }
        await store.receive(.changeFinished(confirmed, nil)) {
            $0.status = confirmed
            $0.requestedEnabled = nil
        }
        await store.finish()
    }

    @Test func `failed registration restores system state and shows an error`() async {
        let error = NSError(domain: "LoginItemTests", code: 1)
        let failure = Failure(error)
        let store = TestStore(initialState: GeneralSettingsFeature.State(status: .disabled)) {
            GeneralSettingsFeature()
        } withDependencies: {
            $0.continuousClock = TestClock()
            $0.loginItem.setEnabled = { _ in throw error }
            $0.loginItem.status = { .disabled }
        }
        await store.send(.view(.launchAtLoginChanged(true))) { $0.requestedEnabled = true }
        await store.receive(.changeFinished(.disabled, failure)) {
            $0.requestedEnabled = nil
            $0.error = String(localized: .loginItemUpdateFailed)
        }
        #expect(!store.state.launchAtLogin)
        await store.finish()
    }

    @Test func `pending approval keeps the request and does not show A generic failure`() async {
        let error = NSError(domain: "LoginItemTests", code: 2)
        let failure = Failure(error)
        let store = TestStore(initialState: GeneralSettingsFeature.State(status: .disabled)) {
            GeneralSettingsFeature()
        } withDependencies: {
            $0.continuousClock = TestClock()
            $0.loginItem.setEnabled = { _ in throw error }
            $0.loginItem.status = { .requiresApproval }
        }
        await store.send(.view(.launchAtLoginChanged(true))) { $0.requestedEnabled = true }
        await store.receive(.changeFinished(.requiresApproval, failure)) {
            $0.status = .requiresApproval
            $0.requestedEnabled = nil
        }
        #expect(store.state.launchAtLogin)
        #expect(store.state.error == nil)
        await store.finish()
    }

    @Test func `returning to the app reflects changes made in system settings`() async {
        let store = TestStore(initialState: GeneralSettingsFeature.State(status: .enabled)) {
            GeneralSettingsFeature()
        } withDependencies: {
            $0.loginItem.status = { .disabled }
        }
        await store.send(.view(.applicationBecameActive))
        await store.receive(.statusReceived(.disabled)) { $0.status = .disabled }
        await store.finish()
    }

    @Test func `pending change rejects another toggle and ignores old status reads`() async {
        let store = TestStore(
            initialState: GeneralSettingsFeature.State(status: .disabled, requestedEnabled: true)
        ) {
            GeneralSettingsFeature()
        }
        await store.send(.view(.launchAtLoginChanged(false)))
        await store.send(.view(.applicationBecameActive))
        await store.send(.statusReceived(.disabled))
        await store.finish()
    }

    @Test func `unavailable registration cannot be changed`() async {
        let store = TestStore(initialState: GeneralSettingsFeature.State(status: .unavailable)) {
            GeneralSettingsFeature()
        }
        await store.send(.view(.launchAtLoginChanged(true)))
        await store.finish()
    }
}
