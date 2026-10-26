@testable import FluidtimeCore
import Foundation
import Testing

struct TimeAnalysisTests {
    @Test func `attendance includes lunch and gaps while work excludes both`() throws {
        let entries = try [
            AnalyticsFixtures.entry("morning", start: "2026-10-22T09:00:00Z", end: "2026-10-22T12:00:00Z"),
            AnalyticsFixtures.entry("afternoon", start: "2026-10-22T13:00:00Z", end: "2026-10-22T15:00:00Z"),
            AnalyticsFixtures.entry("late", start: "2026-10-22T15:30:00Z", end: "2026-10-22T17:00:00Z")
        ]
        let end = try AnalyticsFixtures.date("2026-10-23T00:00:00Z")
        let interval = try DateInterval(start: AnalyticsFixtures.date("2026-10-22T00:00:00Z"), end: end)
        let analysis = try TimeAnalysis(
            entries: entries,
            calendar: AnalyticsFixtures.calendar(),
            interval: interval,
            now: end
        )
        #expect(analysis.work == 6.5 * 3600)
        #expect(analysis.lunch == 3600)
        #expect(analysis.gaps == 1800)
        #expect(analysis.timeAtWork == 8 * 3600)
        #expect(analysis.days.count == 1)
    }

    @Test func `overlap cannot double count tracked work or project totals`() throws {
        let entries = try [
            AnalyticsFixtures.entry(
                "first",
                start: "2026-10-22T09:00:00Z",
                end: "2026-10-22T12:00:00Z",
                project: "one"
            ),
            AnalyticsFixtures.entry(
                "second",
                start: "2026-10-22T11:00:00Z",
                end: "2026-10-22T13:00:00Z",
                project: "two"
            )
        ]
        let end = try AnalyticsFixtures.date("2026-10-23T00:00:00Z")
        let interval = try DateInterval(start: AnalyticsFixtures.date("2026-10-22T00:00:00Z"), end: end)
        let analysis = try TimeAnalysis(
            entries: entries,
            calendar: AnalyticsFixtures.calendar(),
            interval: interval,
            now: end
        )
        #expect(analysis.work == 4 * 3600)
        #expect(analysis.lunch == 0)
        #expect(analysis.projectTotals.values.reduce(0, +) == analysis.work)
        #expect(TrackedTime.total(entries, in: interval, now: end) == analysis.work)
    }

    @Test func `running entry advances attendance and appears only once`() throws {
        let running = try AnalyticsFixtures.entry("same", start: "2026-10-22T09:00:00Z", end: nil)
        let now = try AnalyticsFixtures.date("2026-10-22T10:00:00Z")
        let interval = try DateInterval(start: AnalyticsFixtures.date("2026-10-22T00:00:00Z"), duration: 86400)
        let calendar = try AnalyticsFixtures.calendar()
        let first = TimeAnalysis(entries: [running, running], calendar: calendar, interval: interval, now: now)
        let next = TimeAnalysis(
            entries: [running],
            calendar: calendar,
            interval: interval,
            now: now.addingTimeInterval(1)
        )
        #expect(first.work == 3600)
        #expect(first.timeAtWork == 3600)
        #expect(next.work == 3601)
        #expect(next.timeAtWork == 3601)
    }

    @Test func `midnight clipping respects a daylight saving transition`() throws {
        let calendar = try AnalyticsFixtures.calendar("Europe/Prague")
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 26)))
        let entry = try AnalyticsFixtures.entry("night", start: "2026-10-24T21:00:00Z", end: "2026-10-25T04:00:00Z")
        let analysis = TimeAnalysis(
            entries: [entry],
            calendar: calendar,
            interval: DateInterval(start: start, end: end),
            now: end
        )
        #expect(analysis.work == 7 * 3600)
        #expect(analysis.days.map(\.work) == [3600, 6 * 3600])
        #expect(analysis.timeAtWork == analysis.work)
    }

    @Test func `average day basis includes empty days only when selected`() throws {
        let calendar = try AnalyticsFixtures.calendar()
        let start = try AnalyticsFixtures.date("2026-10-22T00:00:00Z")
        let end = try AnalyticsFixtures.date("2026-10-24T00:00:00Z")
        let entry = try AnalyticsFixtures.entry("work", start: "2026-10-22T09:00:00Z", end: "2026-10-22T13:00:00Z")
        let analysis = TimeAnalysis(
            entries: [entry],
            calendar: calendar,
            interval: DateInterval(start: start, end: end),
            now: end
        )
        #expect(analysis.averages(basis: .trackedDays, calendar: calendar).day == 4 * 3600)
        #expect(analysis.averages(basis: .calendarDays, calendar: calendar).day == 2 * 3600)
        #expect(analysis.averages(basis: .weekdays, calendar: calendar).day == 2 * 3600)
    }
}
