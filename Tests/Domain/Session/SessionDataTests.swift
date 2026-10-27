@testable import FluidtimeCore
import Foundation
import Testing

struct SessionDataTests {
    @Test func `recent entries keep the five newest unique completed work entries`() {
        let now = Date(timeIntervalSince1970: 1_792_620_000)
        var data = SessionData()
        data.entries = (0 ..< 10).reversed().map { (index: Int) -> TimeEntry in
            let start = now.addingTimeInterval(Double(-index * 3600))
            let end: Date? = index == 1 ? nil : now
            let description = index == 3 ? "Work 0" : "Work \(index)"
            return TimeEntry(
                id: "\(index)", start: start, end: end, description: description,
                projectId: nil, taskId: nil, organizationId: "org", userId: "me", billable: false,
                tags: []
            )
        }

        #expect(data.recentEntries.map(\.id) == ["0", "2", "4", "5", "6"])
    }

    @Test(arguments: ["org", "other-org"])
    func `a replacement server timer removes stale running intervals`(_ organization: String) throws {
        let now = try AnalyticsFixtures.date("2026-10-01T12:00:00Z")
        let stale = try AnalyticsFixtures.entry("stale", start: "2026-10-01T08:00:00Z", end: nil)
        let completed = try AnalyticsFixtures.entry(
            "completed", start: "2026-10-01T07:00:00Z", end: "2026-10-01T08:00:00Z"
        )
        let replacement = try TimeEntry(
            id: "replacement", start: AnalyticsFixtures.date("2026-10-01T11:00:00Z"), end: nil,
            description: "Work", projectId: nil, taskId: nil, organizationId: organization,
            userId: "me", billable: false, tags: []
        )
        var data = SessionData()
        data.memberships = [.init(id: "member", organization: .init(id: "org", name: "Test"))]
        data.selectedMembershipId = "member"
        data.entries = [completed, stale]
        data.active = stale
        data.lastFullSync = now

        data.apply(replacement, at: now)

        #expect(data.active == replacement)
        #expect(data.entries == (organization == "org" ? [completed, replacement] : [completed]))
        #expect(data.lastFullSync == nil)
        #expect(TrackedTime.total(data.entries, in: DateInterval(start: completed.start, end: now), now: now)
            == (organization == "org" ? 7200 : 3600))
    }

    @Test(arguments: ["UTC", "Europe/Prague"])
    func `month totals clip to account midnight and count running overlaps once`(_ zone: String) throws {
        var data = SessionData()
        data.user = SolidtimeUser(id: "me", name: "Alex", timezone: zone, weekStart: "monday")
        let now = try AnalyticsFixtures.date("2026-10-01T01:00:00Z")
        data.entries = try [
            AnalyticsFixtures.entry("previous", start: "2026-09-29T09:00:00Z", end: "2026-09-29T10:00:00Z"),
            AnalyticsFixtures.entry("boundary", start: "2026-09-30T21:00:00Z", end: "2026-09-30T23:00:00Z"),
            AnalyticsFixtures.entry("running", start: "2026-10-01T00:00:00Z", end: nil),
            AnalyticsFixtures.entry("overlap", start: "2026-10-01T00:00:00Z", end: "2026-10-01T00:30:00Z"),
            AnalyticsFixtures.entry("future", start: "2026-10-02T00:00:00Z", end: nil)
        ]
        let expected: TimeInterval = zone == "UTC" ? 3600 : 7200
        #expect(data.total(in: .month, at: now) == expected)
        #expect(data.totals(at: now).today == expected)
        #expect(SessionData().total(in: .month, at: now) == 0)
    }
}
