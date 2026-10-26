import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

@MainActor
struct EarningsPrivacyTests {
    @Test func `each reveal requires a new Touch ID verification`() async {
        let authentications = LockIsolated(0)
        let saved = EarningsSettings(currency: "USD", hourlyRate: 25)
        let store = TestStore(initialState: EarningsFeature.State(accountScope: "test")) { EarningsFeature() }
            withDependencies: {
                $0.uuid = .incrementing
                $0.continuousClock = TestClock()
                $0.biometrics.authenticate = { authentications.withValue { $0 += 1 }; return true }
                $0.earnings.load = { _ in saved }
            }
        for index in 0 ..< 2 {
            await store.send(.view(.reveal(.preview))) {
                $0.pendingSurface = .preview
                $0.operation = UUID(index)
            }
            await store.receive(.unlockResponse(UUID(index), .success(saved))) {
                $0.pendingSurface = nil
                $0.operation = nil
                $0.surface = .preview
                $0.settings = saved
                $0.savedSettings = saved
            }
            await store.send(.view(.conceal(.preview))) { $0 = .init(accountScope: "test") }
        }
        #expect(authentications.value == 2)
        await store.finish()
    }

    @Test func `a late authentication result after hiding cannot reveal private values`() async {
        var initial = EarningsFeature.State(accountScope: "test")
        initial.pendingSurface = .settings
        initial.operation = UUID(0)
        let store = TestStore(initialState: initial) { EarningsFeature() }
        await store.send(.view(.conceal(.settings))) { $0 = .init(accountScope: "test") }
        await store.send(.unlockResponse(UUID(0), .success(EarningsSettings(currency: "USD", hourlyRate: 25))))
        #expect(store.state.settings == nil)
        await store.finish()
    }

    @Test func `unavailable Touch ID keeps values hidden and never reads Keychain`() async {
        let failure = Failure(AppError.message(String(localized: .earningsTouchIdUnavailable)))
        let store = TestStore(initialState: EarningsFeature.State(accountScope: "test")) { EarningsFeature() }
            withDependencies: {
                $0.uuid = .constant(UUID(0))
                $0.continuousClock = TestClock()
                $0.biometrics.authenticate = { throw failure }
            }
        await store.send(.view(.reveal(.preview))) {
            $0.pendingSurface = .preview
            $0.operation = UUID(0)
        }
        await store.receive(.unlockResponse(UUID(0), .failure(failure))) {
            $0.pendingSurface = nil
            $0.operation = nil
            $0.error = failure.message
        }
        #expect(store.state.settings == nil)
        await store.finish()
    }
}
