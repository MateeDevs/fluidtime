@testable import FluidtimeCore
import Foundation
import Testing

struct HistoryPresentationTests {
    @Test func `history preparation groups sorted entries and resolves projects and scoped pins`() async throws {
        let calendar = try AnalyticsFixtures.calendar("UTC")
        let now = try AnalyticsFixtures.date("2026-10-23T12:00:00Z")
        let project = Project(
            id: "project",
            name: "Hidden project",
            color: "123456",
            isArchived: false,
            isBillable: true
        )
        let entries = try [
            entry("older", "2026-10-22T08:00:00Z", projectID: "project"),
            entry("newer", "2026-10-23T08:00:00Z", projectID: "missing"),
            entry("latest", "2026-10-23T09:00:00Z", projectID: "project")
        ]
        let presets = [
            TimerPreset(id: UUID(), scope: "account", description: "older", projectId: "project"),
            TimerPreset(id: UUID(), scope: "other-account", description: "latest", projectId: "project")
        ]
        let input = HistoryPresentation.Input(scope: "account", entries: entries, projects: [project],
                                              presets: presets, filter: HistoryFilter(), calendar: calendar,
                                              day: calendar.startOfDay(for: now))
        let result = try await HistoryPresentation.prepare(input, at: now)
        #expect(result.sections.map { $0.rows.map(\.id) } == [["latest", "newer"], ["older"]])
        #expect(result.sections[0].rows[0].project == project)
        #expect(result.sections[0].rows[1].project == nil)
        #expect(!result.sections[0].rows[0].isPinned)
        #expect(result.sections[1].rows[0].isPinned)
    }

    private func entry(_ id: String, _ start: String, projectID: String) throws -> TimeEntry {
        let date = try AnalyticsFixtures.date(start)
        return TimeEntry(id: id, start: date, end: date.addingTimeInterval(1800), description: id,
                         projectId: projectID, taskId: nil, organizationId: "org", userId: "me",
                         billable: true, tags: [])
    }
}
