import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `explicitly opening the app presents the main window`() async {
        let opens = LockIsolated(0)
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() } withDependencies: {
            $0.system.openMainWindow = { opens.withValue { $0 += 1 } }
        }
        await store.send(.interface(.openPrimaryInterface))
        await store.finish()
        #expect(opens.value == 1)
    }

    @Test func `background polling is cancellable and read only`() async {
        let clock = TestClock()
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.uuid = .constant(id)
            $0.preferences.load = { .init() }
            $0.credentials.read = { _ in nil }
        }
        await store.send(.interface(.start)) { $0.lifecycle = .restoring(self.id) }
        await store.receive(.restored(id, .init(), .success(nil))) { $0.lifecycle = .running(self.id) }
        await store.send(.interface(.start)) // Starting again must not create another poller.
        await clock.advance(by: .seconds(30))
        await store.receive(.refreshRequested(full: false))
        await store.send(.interface(.shutdown)) { $0.lifecycle = .stopped }
        await store.finish()
    }

    @Test func `late restore is ignored after shutdown and restart`() async {
        var initial = state
        initial.lifecycle = .restoring(id)
        let store = TestStore(initialState: initial) { AppFeature() }
        await store.send(.interface(.shutdown)) { $0.lifecycle = .stopped }
        await store.send(.restored(id, .init(instance: "https://old.example.invalid"), .success(connection)))
        await store.finish()

        initial.lifecycle = .restoring(UUID(1))
        let restarted = TestStore(initialState: initial) { AppFeature() }
        await restarted.send(.restored(id, .init(), .success(connection)))
        await restarted.finish()
    }

    @Test func `restore failure keeps saved instance and display preferences`() async {
        var initial = AppFeature.State()
        initial.lifecycle = .restoring(id)
        let saved = AppPreferences(
            instance: "https://custom.example.invalid", membershipId: "saved", menuBarDisplay: .indicator
        )
        let failure = Failure(AppError.message("Test Keychain failure"))
        let store = TestStore(initialState: initial) { AppFeature() }
        await store.send(.restored(id, saved, .failure(failure))) {
            $0.lifecycle = .running(self.id)
            $0.preferences = saved
            $0.instanceAddress = saved.instance
            $0.error = failure.message
        }
        await store.finish()
    }
}
