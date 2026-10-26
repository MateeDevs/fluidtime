@testable import FluidtimeCore
import Foundation
import Testing

struct HistoryExportTests {
    @Test func `history filters descriptions projects and billability together`() throws {
        let now = try AnalyticsFixtures.date("2026-10-22T18:00:00Z")
        let calendar = try AnalyticsFixtures.calendar()
        let first = try AnalyticsFixtures.entry(
            "first",
            start: "2026-10-22T09:00:00Z",
            end: "2026-10-22T10:00:00Z",
            project: "a",
            description: "Design review"
        )
        let other = try AnalyticsFixtures.entry(
            "other",
            start: "2026-10-22T10:00:00Z",
            end: "2026-10-22T11:00:00Z",
            billable: false,
            description: "Design planning"
        )
        var filter = HistoryFilter()
        filter.search = "review"
        filter.projectId = "a"
        filter.billability = .billable
        #expect(filter.entries([first, other], calendar: calendar, now: now).map(\.id) == ["first"])
    }

    @Test func `CSV quotes fields and prevents spreadsheet formula execution`() {
        #expect(CSVDocument.cell("a,\"b\"\nline") == "\"a,\"\"b\"\"\nline\"")
        #expect(CSVDocument.cell("=SUM(A1:A2)").hasPrefix("\"'="))
        #expect(CSVDocument.cell("  +SUM(A1:A2)").hasPrefix("\"'  +"))
        #expect(CSVDocument.cell("ordinary text") == "\"ordinary text\"")
    }

    @Test func `entry export includes tracked duration and client billability`() throws {
        let entry = try AnalyticsFixtures.entry(
            "running", start: "2026-10-22T09:30:00Z", end: nil, billable: false, description: "Review"
        )
        let now = try AnalyticsFixtures.date("2026-10-22T10:00:00Z")
        let rows = CSVDocument.entries([entry], projects: [], now: now).contents.components(separatedBy: "\r\n")
        #expect(rows.count == 2)
        #expect(rows[0].components(separatedBy: ",").count == 6)
        #expect(rows[1] == "\"Review\",\"\",\"2026-10-22T09:30:00Z\",\"\",\"1800\",\"No\"")
    }

    @Test func `daily exports use the account date and do not include rates`() throws {
        let calendar = try AnalyticsFixtures.calendar("Europe/Prague")
        let start = try AnalyticsFixtures.date("2026-10-21T22:00:00Z")
        let end = try AnalyticsFixtures.date("2026-10-22T22:00:00Z")
        let entry = try AnalyticsFixtures.entry("work", start: "2026-10-22T08:00:00Z", end: "2026-10-22T09:00:00Z")
        let analysis = TimeAnalysis(
            entries: [entry],
            calendar: calendar,
            interval: DateInterval(start: start, end: end),
            now: end
        )
        let document = CSVDocument.summary(analysis, calendar: calendar)
        #expect(document.contents.contains("\"2026-10-22\""))
        #expect(document.contents.contains("\"3600\""))
        #expect(!document.contents.contains("USD"))
    }
}
