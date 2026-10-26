@testable import FluidtimeCore
import Foundation
import Testing

struct MenuBarPresentationTests {
    private var now: Date {
        date("2026-10-21T10:15:45Z")
    }

    private func date(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text)!
    }

    private func entry(_ id: String, start: String, end: String?) -> TimeEntry {
        TimeEntry(
            id: id, start: date(start), end: end.map(date), description: nil,
            projectId: nil, taskId: nil, organizationId: "org", userId: "me", billable: false, tags: []
        )
    }

    private var data: SessionData {
        var data = SessionData()
        data.user = SolidtimeUser(id: "me", name: "Alex", timezone: "UTC", weekStart: "monday")
        data.entries = [
            entry("completed", start: "2026-10-21T09:00:00Z", end: "2026-10-21T10:00:00Z"),
            entry("running", start: "2026-10-21T10:00:00Z", end: nil),
            entry("yesterday", start: "2026-10-20T09:00:00Z", end: "2026-10-20T10:00:00Z")
        ]
        data.active = data.entries[1]
        data.lastSynced = now
        return data
    }

    @Test func `today includes the running timer and updates live`() {
        let preferences = AppPreferences(menuBarDisplay: .today)
        let first = MenuBarPresentation(data: data, preferences: preferences, now: now)
        let next = MenuBarPresentation(data: data, preferences: preferences, now: now.addingTimeInterval(1))
        #expect(first.text == "1:15:45")
        #expect(next.text == "1:15:46")
    }

    @Test func `today remains visible without A running timer`() {
        var data = data
        data.active = nil
        data.entries.removeAll { $0.end == nil }
        let result = MenuBarPresentation(data: data, preferences: .init(menuBarDisplay: .today), now: now)
        #expect(result.text == "1:00:00")
    }

    @Test(arguments: [MenuBarDisplay.elapsed, .today])
    func `seconds can be hidden`(_ display: MenuBarDisplay) {
        let preferences = AppPreferences(menuBarDisplay: display, menuBarShowsSeconds: false)
        let result = MenuBarPresentation(data: data, preferences: preferences, now: now)
        #expect(result.text == (display == .elapsed ? "0:15" : "1:15"))
    }

    @Test func `active indicator follows the running entry`() {
        let preferences = AppPreferences(menuBarDisplay: .indicator)
        let running = MenuBarPresentation(data: data, preferences: preferences, now: now)
        #expect(running.showsActiveIndicator)
        #expect(running.text == nil)
        var idle = data
        idle.active = nil
        #expect(!MenuBarPresentation(data: idle, preferences: preferences, now: now).showsActiveIndicator)
    }

    @Test func `clock icon keeps the active indicator while hiding duration`() {
        let result = MenuBarPresentation(data: data, preferences: .init(menuBarDisplay: .clock), now: now)
        #expect(result.text == nil)
        #expect(result.showsActiveIndicator)
    }

    @Test func `disconnected account does not display an unverified total`() {
        let result = MenuBarPresentation(data: .init(), preferences: .init(menuBarDisplay: .today), now: now)
        #expect(result.text == nil)
    }

    @Test(arguments: [MenuBarDisplay.elapsed, .today, .week, .clock])
    func `project color is optional and follows the active project in every display mode`(
        _ display: MenuBarDisplay
    ) throws {
        var data = data
        data.memberships = [Membership(id: "member", organization: .init(id: "org", name: "Test"))]
        data.selectedMembershipId = "member"
        let original = try #require(data.active)
        data.active = TimeEntry(id: original.id, start: original.start, end: nil, description: nil,
                                projectId: "project", taskId: nil, organizationId: "org", userId: "me",
                                billable: true, tags: [])
        data.projects = [Project(id: "project", name: "Work", color: "#123456", isArchived: false, isBillable: true)]
        var preferences = AppPreferences(menuBarDisplay: display)
        #expect(MenuBarPresentation(data: data, preferences: preferences, now: now).activeProjectColor == nil)
        preferences.menuBarUsesProjectColor = true
        #expect(MenuBarPresentation(data: data, preferences: preferences, now: now).activeProjectColor == "#123456")
        data.selectedMembershipId = "another-organization"
        #expect(MenuBarPresentation(data: data, preferences: preferences, now: now).activeProjectColor == nil)
        data.selectedMembershipId = "member"
        data.active = nil
        #expect(MenuBarPresentation(data: data, preferences: preferences, now: now).activeProjectColor == nil)
    }
}
