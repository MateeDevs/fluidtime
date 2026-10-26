import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

@MainActor
struct EarningsFeatureTests {
    private let settings = EarningsSettings(currency: "USD", hourlyRate: 25)

    @Test func `private values stay hidden until Touch ID succeeds and the rate is loaded`() async {
        let saved = settings
        let store = TestStore(initialState: EarningsFeature.State(accountScope: "test")) { EarningsFeature() }
            withDependencies: {
                $0.uuid = .constant(UUID(0))
                $0.continuousClock = TestClock()
                $0.biometrics.authenticate = { true }
                $0.earnings.load = { scope in #expect(scope == "test"); return saved }
            }
        await store.send(.view(.reveal(.preview))) {
            $0.pendingSurface = .preview
            $0.operation = UUID(0)
        }
        #expect(store.state.settings == nil)
        await store.receive(.unlockResponse(UUID(0), .success(saved))) {
            $0.pendingSurface = nil
            $0.operation = nil
            $0.surface = .preview
            $0.settings = saved
            $0.savedSettings = saved
        }
        await store.send(.view(.conceal(.preview))) {
            $0.surface = nil
            $0.settings = nil
            $0.savedSettings = nil
        }
        await store.finish()
    }

    @Test func `cancelled authentication never reads Keychain or reveals values`() async {
        let store = TestStore(initialState: EarningsFeature.State(accountScope: "test")) { EarningsFeature() }
            withDependencies: {
                $0.uuid = .constant(UUID(0))
                $0.continuousClock = TestClock()
                $0.biometrics.authenticate = { false }
            }
        await store.send(.view(.reveal(.settings))) {
            $0.pendingSurface = .settings
            $0.operation = UUID(0)
        }
        await store.receive(.unlockResponse(UUID(0), .success(nil))) {
            $0.pendingSurface = nil
            $0.operation = nil
        }
        #expect(store.state.settings == nil)
        await store.finish()
    }

    @Test func `account changes scrub values and reject a late authentication response`() async {
        var state = EarningsFeature.State(accountScope: "old")
        state.settings = settings
        state.surface = .settings
        state.operation = UUID(0)
        let store = TestStore(initialState: state) { EarningsFeature() }
        await store.send(.interface(.contextChanged("new"))) { $0 = .init(accountScope: "new") }
        await store.send(.unlockResponse(UUID(0), .success(settings)))
        await store.finish()
    }

    @Test func `preview cannot edit the rate and failed settings saves preserve the draft`() async {
        var state = EarningsFeature.State(accountScope: "test")
        state.surface = .preview
        state.settings = settings
        state.savedSettings = settings
        let preview = TestStore(initialState: state) { EarningsFeature() }
        await preview.send(.view(.rateChanged(30)))
        await preview.send(.view(.save))
        await preview.finish()
        state.surface = .settings
        let store = TestStore(initialState: state) { EarningsFeature() } withDependencies: {
            $0.uuid = .constant(UUID(0))
            $0.continuousClock = TestClock()
            $0.earnings.save = { _, _ in throw AppError.message("Test failure") }
        }
        await store.send(.view(.rateChanged(30))) { $0.settings?.hourlyRate = 30 }
        await store.send(.view(.save)) { $0.operation = UUID(0) }
        await store.receive(.saveResponse(UUID(0), Failure(AppError.message("Test failure")))) {
            $0.operation = nil
            $0.error = String(localized: .earningsSaveFailed)
        }
        #expect(store.state.settings?.hourlyRate == 30)
        await store.finish()
    }
}
