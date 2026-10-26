@testable import FluidtimeCore
import Foundation
import Testing

struct HistoryBoundaryTests {
    @Test(arguments: ["UTC", "Europe/Prague", "America/New_York"])
    func `completed entries require positive overlap with the selected month`(_ zone: String) throws {
        let calendar = try AnalyticsFixtures.calendar(zone)
        let now = try AnalyticsFixtures.date("2026-10-23T12:00:00Z")
        let interval = try #require(calendar.dateInterval(of: .month, for: now))
        let boundary = interval.start
        let entries = [
            entry("before", start: boundary.addingTimeInterval(-7200), end: boundary.addingTimeInterval(-3600)),
            entry("ends-at-start", start: boundary.addingTimeInterval(-3600), end: boundary),
            entry("crosses-start", start: boundary.addingTimeInterval(-3600), end: boundary.addingTimeInterval(1)),
            entry("starts-at-end", start: interval.end, end: interval.end.addingTimeInterval(3600))
        ]
        #expect(HistoryFilter().entries(entries, calendar: calendar, now: now).map(\.id) == ["crosses-start"])
        #expect(HistoryFilter().entries([entry("running", start: boundary, end: nil)],
                                        calendar: calendar, now: boundary).map(\.id) == ["running"])
    }

    @Test(arguments: ["2026-03-29T12:00:00Z", "2026-10-25T12:00:00Z"])
    func `custom days use account midnight across daylight saving changes`(_ timestamp: String) throws {
        let calendar = try AnalyticsFixtures.calendar("Europe/Prague")
        let now = try AnalyticsFixtures.date(timestamp)
        let lower = calendar.startOfDay(for: now)
        let upper = try #require(calendar.date(byAdding: .day, value: 1, to: lower))
        var filter = HistoryFilter()
        filter.period = .custom
        filter.start = now
        filter.end = now
        let entries = [
            entry("previous-day", start: lower.addingTimeInterval(-3600), end: lower),
            entry("selected-day", start: lower, end: upper),
            entry("next-day", start: upper, end: upper.addingTimeInterval(3600))
        ]
        #expect(filter.entries(entries, calendar: calendar, now: upper).map(\.id) == ["selected-day"])
    }

    private func entry(_ id: String, start: Date, end: Date?) -> TimeEntry {
        TimeEntry(id: id, start: start, end: end, description: "Work", projectId: nil, taskId: nil,
                  organizationId: "org", userId: "me", billable: true, tags: [])
    }
}
