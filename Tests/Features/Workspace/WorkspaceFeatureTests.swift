import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

@MainActor
struct WorkspaceFeatureTests {
    @Test func `history deletion is delegated to the account owner`() async throws {
        let entry = try AnalyticsFixtures.entry("delete", start: "2026-10-22T09:00:00Z", end: "2026-10-22T10:00:00Z")
        let store = TestStore(initialState: WorkspaceFeature.State()) { WorkspaceFeature() }
        await store.send(.view(.deleteTapped(entry)))
        await store.receive(.delegate(.delete(entry)))
        await store.finish()
    }

    @Test func `find switches to history and requests focus again on repeated commands`() async {
        let store = TestStore(initialState: WorkspaceFeature.State()) { WorkspaceFeature() }
        await store.send(.view(.find)) {
            $0.tab = .history
            $0.searchFocusRequest = 1
        }
        await store.send(.view(.find)) { $0.searchFocusRequest = 2 }
    }

    @Test func `changing accounts updates history context without private state`() async throws {
        var state = WorkspaceFeature.State()
        state.accountScope = "old"
        let calendar = try AnalyticsFixtures.calendar()
        let now = try AnalyticsFixtures.date("2026-10-22T12:00:00Z")
        let store = TestStore(initialState: state) { WorkspaceFeature() } withDependencies: {
            $0.date.now = now
        }
        await store.send(.view(.appeared("new", calendar))) {
            $0.accountScope = "new"
            $0.calendar = calendar
            $0.customStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            $0.customEnd = now
            $0.history.start = $0.customStart
            $0.history.end = now
        }
        await store.finish()
    }
}
