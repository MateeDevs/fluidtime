@testable import FluidtimeCore
import Foundation
import Testing

struct WorkFinishTests {
    @Test(arguments: [0.0, -1, .infinity, .nan])
    func `disabled or invalid targets have no projection`(_ target: Double) {
        #expect(WorkFinish.calculate(targetHours: target, tracked: 0, now: .distantPast) == nil)
    }

    @Test(arguments: [8.0, 9])
    func `meeting or exceeding the target reports completion`(_ hours: Double) {
        #expect(WorkFinish.calculate(targetHours: 8, tracked: hours * 3600, now: .distantPast) == .targetReached)
    }

    @Test func `remaining work assumes an immediate start and excludes future breaks`() throws {
        let now = try AnalyticsFixtures.date("2026-10-29T14:00:00Z")
        let expected = try AnalyticsFixtures.date("2026-10-29T17:00:00Z")
        #expect(WorkFinish.calculate(targetHours: 8, tracked: 5 * 3600, now: now) == .expected(expected))
        #expect(WorkFinish.calculate(targetHours: 8, tracked: 5 * 3600, now: now.addingTimeInterval(600))
            == .expected(expected.addingTimeInterval(600)))
    }

    @Test func `running work keeps the finish stable and counts overlapping work once`() throws {
        var data = session()
        data.entries = try [
            AnalyticsFixtures.entry("morning", start: "2026-10-29T08:00:00Z", end: "2026-10-29T12:00:00Z"),
            AnalyticsFixtures.entry("overlap", start: "2026-10-29T09:00:00Z", end: "2026-10-29T10:00:00Z"),
            AnalyticsFixtures.entry("running", start: "2026-10-29T13:00:00Z", end: nil)
        ]
        data.active = data.entries.last
        let expected = try AnalyticsFixtures.date("2026-10-29T17:00:00Z")
        for time in ["2026-10-29T14:00:00Z", "2026-10-29T15:00:00Z"] {
            let now = try AnalyticsFixtures.date(time)
            #expect(WorkFinish.calculate(targetHours: 8, tracked: data.totals(at: now).today, now: now)
                == .expected(expected))
        }
    }

    @Test func `another organization timer does not advance selected organization work`() throws {
        var data = session()
        data.entries = try [
            AnalyticsFixtures.entry("done", start: "2026-10-29T08:00:00Z", end: "2026-10-29T10:00:00Z")
        ]
        let now = try AnalyticsFixtures.date("2026-10-29T14:00:00Z")
        let other = try TimeEntry(
            id: "other", start: AnalyticsFixtures.date("2026-10-29T11:00:00Z"), end: nil,
            description: "Work", projectId: nil, taskId: nil, organizationId: "other-org",
            userId: "me", billable: false, tags: []
        )
        data.apply(other, at: now)
        #expect(data.activeInAnotherOrganization)
        #expect(WorkFinish.calculate(targetHours: 8, tracked: data.totals(at: now).today, now: now)
            == .expected(now.addingTimeInterval(6 * 3600)))
    }

    @Test func `projection can cross midnight and the new day resets tracked work`() throws {
        var data = session(zone: "Europe/Prague")
        data.entries = try [
            AnalyticsFixtures.entry("done", start: "2026-10-29T20:00:00Z", end: "2026-10-29T21:00:00Z")
        ]
        let before = try AnalyticsFixtures.date("2026-10-29T22:00:00Z")
        let after = try AnalyticsFixtures.date("2026-10-29T23:00:00Z")
        #expect(WorkFinish.calculate(targetHours: 2, tracked: data.totals(at: before).today, now: before)
            == .expected(after))
        #expect(WorkFinish.calculate(targetHours: 2, tracked: data.totals(at: after).today, now: after)
            == .expected(after.addingTimeInterval(7200)))
    }

    @Test(arguments: [
        ("2026-03-29T00:30:00Z", "2026-03-29T02:30:00Z"),
        ("2026-10-25T00:30:00Z", "2026-10-25T02:30:00Z")
    ])
    func `daylight saving projections use elapsed work hours`(_ dates: (String, String)) throws {
        let now = try AnalyticsFixtures.date(dates.0)
        let expected = try AnalyticsFixtures.date(dates.1)
        let data = session(zone: "Europe/Prague")
        #expect(WorkFinish.calculate(targetHours: 2, tracked: data.totals(at: now).today, now: now)
            == .expected(expected))
    }

    private func session(zone: String = "UTC") -> SessionData {
        var data = SessionData()
        data.user = SolidtimeUser(id: "me", name: "Alex", timezone: zone, weekStart: "monday")
        data.memberships = [.init(id: "member", organization: .init(id: "org", name: "Test"))]
        data.selectedMembershipId = "member"
        return data
    }
}
