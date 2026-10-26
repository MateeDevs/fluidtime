@testable import FluidtimeCore
import Foundation
import Testing

struct SessionSyncTests {
    @Test func `incremental refresh preserves boundary entry and scopes user`() async throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-10-21T12:00:00Z"))
        let user = SolidtimeUser(id: "me", name: "Alex", timezone: "Europe/Prague", weekStart: "monday")
        let member = Membership(id: "member", organization: .init(id: "org", name: "Test"))
        let weekStart = try #require(user.calendar.dateInterval(of: .weekOfYear, for: date)?.start)
        let crossing = TimeEntry(
            id: "crossing", start: weekStart.addingTimeInterval(-1800), end: weekStart.addingTimeInterval(1800),
            description: nil, projectId: nil, taskId: nil, organizationId: "org", userId: "me", billable: false,
            tags: []
        )
        let active = TimeEntry(
            id: "active", start: date.addingTimeInterval(-600), end: nil, description: nil,
            projectId: nil, taskId: nil, organizationId: "org", userId: "me", billable: false, tags: []
        )
        let otherUser = TimeEntry(
            id: "other", start: date.addingTimeInterval(-600), end: date, description: nil,
            projectId: nil, taskId: nil, organizationId: "org", userId: "someone-else", billable: false, tags: []
        )
        var previous = SessionData()
        previous.user = user
        previous.memberships = [member]
        previous.selectedMembershipId = member.id
        previous.entries = [crossing, active]
        previous.active = active
        previous.lastSynced = date.addingTimeInterval(-30)
        previous.lastFullSync = date.addingTimeInterval(-60)
        previous.syncedWeekStart = weekStart
        var client = SolidtimeClient()
        client.activeEntry = { _ in active }
        client.entries = { _, membership, since in
            #expect(membership.id == "member")
            #expect(since == weekStart)
            return [active, active, otherUser]
        }
        // Account and project endpoints remain unimplemented for incremental refreshes.
        let result = try await SessionSync(client: client).fetch(
            connection: Connection(instance: "https://example.invalid", token: "test"),
            previous: previous, preferredMembershipId: member.id, full: false, now: date
        )
        #expect(Set(result.entries.map(\.id)) == ["crossing", "active"])
        #expect(result.totals(at: date).week == 2400)
    }
}
