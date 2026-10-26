@testable import FluidtimeCore
import Foundation
import Testing

struct EarningsCalculatorTests {
    @Test func `fixed rate applies to all dates and does not deduct inferred lunch twice`() throws {
        let start = try AnalyticsFixtures.date("2026-10-01T00:00:00Z")
        let end = try AnalyticsFixtures.date("2026-10-23T00:00:00Z")
        let entries = try [
            AnalyticsFixtures.entry("old", start: "2026-10-01T09:00:00Z", end: "2026-10-01T10:00:00Z"),
            AnalyticsFixtures.entry("morning", start: "2026-10-22T09:00:00Z", end: "2026-10-22T11:00:00Z"),
            AnalyticsFixtures.entry("afternoon", start: "2026-10-22T12:00:00Z", end: "2026-10-22T13:00:00Z")
        ]
        let analysis = try TimeAnalysis(entries: entries, calendar: AnalyticsFixtures.calendar(),
                                        interval: DateInterval(start: start, end: end), now: end)
        #expect(analysis.lunch == 3600)
        let settings = EarningsSettings(currency: "USD", hourlyRate: 20)
        #expect(EarningsCalculator.estimate(analysis, settings: settings, billableOnly: false) == 80)
    }

    @Test func `nonbillable work is paid by default`() throws {
        let start = try AnalyticsFixtures.date("2026-10-22T00:00:00Z")
        let end = try AnalyticsFixtures.date("2026-10-23T00:00:00Z")
        let entries = try [
            AnalyticsFixtures.entry(
                "work",
                start: "2026-10-22T09:00:00Z",
                end: "2026-10-22T11:00:00Z",
                billable: false
            )
        ]
        let analysis = try TimeAnalysis(entries: entries, calendar: AnalyticsFixtures.calendar(),
                                        interval: DateInterval(start: start, end: end), now: end)
        let settings = EarningsSettings(currency: "USD", hourlyRate: 20)
        #expect(EarningsCalculator.estimate(analysis, settings: settings, billableOnly: false) == 40)
        #expect(EarningsCalculator.estimate(analysis, settings: settings, billableOnly: true) == 0)
        #expect(EarningsCalculator.estimate(analysis, settings: EarningsSettings(), billableOnly: false) == 0)
    }

    @Test func `today earnings use the account day independently of the selected period`() throws {
        let calendar = try AnalyticsFixtures.calendar("Europe/Prague")
        let now = try AnalyticsFixtures.date("2026-10-23T10:00:00Z")
        let entries = try [
            AnalyticsFixtures.entry("previous", start: "2026-09-20T08:00:00Z", end: "2026-09-20T10:00:00Z"),
            AnalyticsFixtures.entry("midnight", start: "2026-10-22T21:00:00Z", end: "2026-10-22T23:00:00Z"),
            AnalyticsFixtures.entry("nonbillable", start: "2026-10-23T08:00:00Z", end: "2026-10-23T09:00:00Z",
                                    billable: false),
            AnalyticsFixtures.entry("running", start: "2026-10-23T09:00:00Z", end: nil),
            AnalyticsFixtures.entry("overlap", start: "2026-10-23T09:00:00Z", end: "2026-10-23T09:30:00Z")
        ]
        let settings = EarningsSettings(currency: "USD", hourlyRate: 20)
        let day = try #require(calendar.dateInterval(of: .day, for: now))
        let today = TimeAnalysis(entries: entries, calendar: calendar, interval: day, now: now)
        let previousMonth = AnalysisPeriod.lastMonth.interval(calendar: calendar, now: now, start: now, end: now)
        let selected = TimeAnalysis(entries: entries, calendar: calendar, interval: previousMonth, now: now)
        #expect(EarningsCalculator.estimate(selected, settings: settings, billableOnly: false) == 40)
        #expect(EarningsCalculator.estimate(today, settings: settings, billableOnly: false) == 60)
        #expect(EarningsCalculator.estimate(today, settings: settings, billableOnly: true) == 40)
    }
}
