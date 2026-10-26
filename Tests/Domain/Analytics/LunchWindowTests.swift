@testable import FluidtimeCore
import Foundation
import Testing

struct LunchWindowTests {
    @Test func `longest qualifying gap counts its full duration and keeps other gaps separate`() throws {
        let intervals = try [
            interval("09:00", "10:00"), interval("10:30", "11:30"), interval("14:30", "15:00"),
            interval("15:15", "17:00")
        ]
        let window = LunchWindow(startMinute: 12 * 60, endMinute: 14 * 60)
        let lunch = try #require(window.longestGap(in: intervals, calendar: AnalyticsFixtures.calendar()))
        #expect(lunch.duration == 3 * 3600)
        #expect(lunch.start == intervals[1].end)
    }

    @Test func `midpoint uses account time zone and an exclusive end boundary`() throws {
        let intervals = try [interval("09:00", "10:30"), interval("11:30", "13:00")]
        let window = LunchWindow(startMinute: 12 * 60, endMinute: 13 * 60)
        #expect(try window.longestGap(in: intervals, calendar: AnalyticsFixtures.calendar()) == nil)
        #expect(try window.longestGap(in: intervals, calendar: AnalyticsFixtures.calendar("Europe/Prague")) == nil)
        let wider = LunchWindow(startMinute: 12 * 60, endMinute: 14 * 60)
        #expect(try wider.longestGap(in: intervals, calendar: AnalyticsFixtures.calendar("Europe/Prague"))?
            .duration == 3600)
    }

    @Test func `overlapping and adjacent timers do not create lunch or a trailing idle estimate`() throws {
        let calendar = try AnalyticsFixtures.calendar()
        let overlapping = try [interval("09:00", "12:00"), interval("11:00", "13:00"), interval("13:00", "14:00")]
        #expect(LunchWindow().longestGap(in: overlapping, calendar: calendar) == nil)
        #expect(try LunchWindow().longestGap(in: [interval("09:00", "12:00")], calendar: calendar) == nil)
    }

    @Test func `equal length gaps choose the first and overnight gaps do not become lunch`() throws {
        let calendar = try AnalyticsFixtures.calendar()
        let intervals = try [interval("09:00", "11:00"), interval("12:00", "13:00"), interval("14:00", "17:00")]
        #expect(LunchWindow().longestGap(in: intervals, calendar: calendar)?.start == intervals[0].end)
        let overnight = try [interval("09:00", "12:00"), DateInterval(
            start: AnalyticsFixtures.date("2026-10-23T12:00:00Z"), duration: 3600
        )]
        #expect(LunchWindow().longestGap(in: overnight, calendar: calendar) == nil)
    }

    private func interval(_ start: String, _ end: String) throws -> DateInterval {
        try DateInterval(start: AnalyticsFixtures.date("2026-10-22T\(start):00Z"),
                         end: AnalyticsFixtures.date("2026-10-22T\(end):00Z"))
    }
}
