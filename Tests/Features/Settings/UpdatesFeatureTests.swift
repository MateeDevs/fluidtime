import ComposableArchitecture
@testable import FluidtimeCore
import Testing

@MainActor
struct UpdatesFeatureTests {
    @Test func `unavailable updater does not invoke framework operations`() async {
        let store = TestStore(initialState: UpdatesFeature.State()) { UpdatesFeature() }
        await store.send(.view(.check))
        await store.send(.view(.automaticChecksChanged(true)))
        await store.send(.view(.automaticInstallationChanged(true)))
        await store.finish()
    }

    @Test func `update checks and preferences go through the library client`() async {
        let status = UpdateStatus(isAvailable: true, canCheck: true)
        let calls = LockIsolated<[String]>([])
        let store = TestStore(initialState: UpdatesFeature.State(status: status)) { UpdatesFeature()
        } withDependencies: {
            $0.updates.check = { calls.withValue { $0.append("check") } }
            $0.updates.setAutomaticChecks = { value in
                #expect(value)
                calls.withValue { $0.append("automatic") }
            }
            $0.updates.setAutomaticInstallation = { value in
                #expect(value)
                calls.withValue { $0.append("install") }
            }
        }
        await store.send(.view(.check))
        await store.finish()
        await store.send(.view(.automaticChecksChanged(true)))
        await store.finish()
        await store.send(.view(.automaticInstallationChanged(true)))
        await store.finish()
        #expect(calls.value == ["check", "automatic", "install"])
        #expect(!store.state.status.automaticallyChecks)
    }

    @Test func `unavailable updater rejects a stale check capability`() async {
        let store = TestStore(initialState: UpdatesFeature.State(status: UpdateStatus(canCheck: true))) {
            UpdatesFeature()
        }
        await store.send(.view(.check))
        await store.finish()
    }

    @Test func `disabled build never starts Sparkle and emits only unavailable status`() async throws {
        try #require(!UpdatesConfiguration.isEnabled)
        let client = UpdatesClient.liveValue
        client.start()
        client.check()
        client.setAutomaticChecks(true)
        client.setAutomaticInstallation(true)
        var iterator = client.statuses().makeAsyncIterator()
        #expect(await iterator.next() == UpdateStatus())
        #expect(await iterator.next() == nil)
    }

    @Test func `manual update link opens GitHub releases without invoking Sparkle`() async {
        let opened = LockIsolated<String?>(nil)
        let store = TestStore(initialState: UpdatesFeature.State()) { UpdatesFeature() } withDependencies: {
            $0.system.openURL = { opened.setValue($0.absoluteString) }
        }
        await store.send(.view(.openReleases))
        await store.finish()
        #expect(opened.value == "https://github.com/MateeDevs/fluidtime/releases")
    }
}
