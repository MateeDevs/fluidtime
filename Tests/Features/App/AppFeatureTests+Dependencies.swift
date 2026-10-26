import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `menu bar seconds preference persists through dependency`() async {
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.preferences.setMenuBarShowsSeconds = { #expect(!$0) }
        }
        await store.send(.view(.binding(.set(\.menuBarShowsSeconds, false)))) { $0.menuBarShowsSeconds = false }
        await store.finish()
    }

    @Test func `application stores keep dependency overrides isolated`() async throws {
        let firstURLs = LockIsolated<[URL]>([])
        let secondURLs = LockIsolated<[URL]>([])
        let first = Store(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.system.openURL = { url in firstURLs.withValue { $0.append(url) } }
        }
        var otherState = AppFeature.State()
        otherState.instanceAddress = "https://example.invalid/solidtime"
        let second = Store(initialState: otherState) {
            AppFeature()
        } withDependencies: {
            $0.system.openURL = { url in secondURLs.withValue { $0.append(url) } }
        }

        await first.send(.view(.openInstanceTapped)).finish()
        await second.send(.view(.openInstanceTapped)).finish()

        #expect(try firstURLs.value == [#require(URL(string: "https://app.solidtime.io"))])
        #expect(try secondURLs.value == [#require(URL(string: "https://example.invalid/solidtime"))])
    }
}
