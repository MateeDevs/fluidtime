@testable import FluidtimeCore
import Foundation
import Testing

struct TrackedTimeTests {
    private func entry(start: String, end: String?) -> TimeEntry {
        TimeEntry(
            id: "entry", start: date(start), end: end.map(date), description: nil,
            projectId: nil, taskId: nil, organizationId: "org", userId: "me",
            billable: false, tags: []
        )
    }

    private func date(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text)!
    }

    @Test func `splits midnight and includes running time once`() {
        let entries = [
            entry(start: "2026-10-20T23:30:00Z", end: "2026-10-21T00:30:00Z"),
            entry(start: "2026-10-21T10:00:00Z", end: nil)
        ]
        let period = DateInterval(start: date("2026-10-21T00:00:00Z"), end: date("2026-10-22T00:00:00Z"))
        #expect(TrackedTime.total(entries, in: period, now: date("2026-10-21T10:15:00Z")) == 2700)
        #expect(TrackedTime.total(entries, in: period, now: date("2026-10-21T10:15:01Z")) == 2701)
    }

    @Test func `clips long running timer at week boundary`() {
        let entries = [entry(start: "2026-10-18T23:00:00Z", end: nil)]
        let period = DateInterval(start: date("2026-10-19T00:00:00Z"), end: date("2026-10-26T00:00:00Z"))
        #expect(TrackedTime.total(entries, in: period, now: date("2026-10-19T01:00:00Z")) == 3600)
    }

    @Test func `respects profile week start and daylight saving`() throws {
        let user = SolidtimeUser(id: "me", name: "Test", timezone: "Europe/Prague", weekStart: "sunday")
        let day = try #require(user.calendar.dateInterval(of: .day, for: date("2026-10-25T12:00:00Z")))
        #expect(day.duration == 25 * 3600)
        let week = try #require(user.calendar.dateInterval(of: .weekOfYear, for: date("2026-10-25T12:00:00Z")))
        #expect(user.calendar.component(.weekday, from: week.start) == 1)
    }

    @Test func `formats long and negative durations`() {
        #expect(TrackedTime.clock(100 * 3600 + 61) == "100:01:01")
        #expect(TrackedTime.clock(-1) == "0:00:00")
    }
}
