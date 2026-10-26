import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

@MainActor
struct WorkspaceHistoryTests {
    @Test func `history preparation applies once and rejects late results`() async throws {
        let calendar = try AnalyticsFixtures.calendar("UTC")
        let now = try AnalyticsFixtures.date("2026-10-23T12:00:00Z")
        let id = UUID()
        let input = HistoryPresentation.Input(scope: "account", entries: [], projects: [], presets: [],
                                              filter: HistoryFilter(), calendar: calendar,
                                              day: calendar.startOfDay(for: now))
        let result = try HistoryPresentation.make(input, at: now)
        let store = TestStore(initialState: WorkspaceFeature.State()) { WorkspaceFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = now
        }
        await store.send(.view(.historyInputChanged(input))) { $0.historyRequestID = id }
        await store.receive(.historyPrepared(id, result)) {
            $0.historyRequestID = nil
            $0.historyPresentation = result
        }
        let stale = HistoryPresentation(scope: "other-account", sections: [])
        await store.send(.historyPrepared(UUID(), stale))
        await store.finish()
    }
}
