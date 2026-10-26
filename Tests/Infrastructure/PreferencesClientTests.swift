@testable import FluidtimeCore
import Foundation
import Testing

struct PreferencesClientTests {
    @Test func `existing workspace preferences preserve targets and reminders with default lunch hours`() throws {
        let json = Data(#"""
        {"presentation":"window","dailyGoalHours":7.5,"weeklyGoalHours":35,"timerFeedback":false,
        "idleReminderMinutes":10,"longTimerReminderHours":3,"presets":[]}
        """#.utf8)
        let settings = try JSONDecoder().decode(WorkspacePreferences.self, from: json)
        #expect(settings.dailyGoalHours == 7.5)
        #expect(settings.weeklyGoalHours == 35)
        #expect(!settings.timerFeedback)
        #expect(settings.idleReminderMinutes == 10)
        #expect(settings.longTimerReminderHours == 3)
        #expect(settings.lunchWindow == LunchWindow())
        let encoded = try JSONEncoder().encode(settings)
        let keys = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(keys["presentation"] == nil)
    }

    @Test func `persists preferences in the provided storage`() throws {
        let suite = "FluidtimeTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let client = PreferencesClient.live(store: PreferencesStore(defaults: defaults))
        #expect(client.load().menuBarShowsSeconds)
        #expect(!client.load().menuBarUsesProjectColor)
        #expect(client.load().projectVisibility.hiddenIDs(in: "account").isEmpty)

        client.setInstance("https://example.invalid/solidtime")
        client.setMembership("member")
        client.setMenuBarDisplay(.today)
        client.setMenuBarShowsSeconds(false)
        client.setMenuBarUsesProjectColor(true)
        var workspace = WorkspacePreferences()
        workspace.lunchWindow = LunchWindow(startMinute: 12 * 60, endMinute: 14 * 60)
        workspace.navigation["account"] = WorkspaceNavigation(destination: "history")
        workspace.dailyGoalHours = 7.5
        workspace.idleReminderMinutes = 10
        client.setWorkspace(workspace)
        var visibility = ProjectVisibilityPreferences()
        visibility.setVisible(false, projectID: "project", in: "account")
        client.setProjectVisibility(visibility)

        let stored = PreferencesStore(defaults: defaults).load()
        #expect(stored.instance == "https://example.invalid/solidtime")
        #expect(stored.membershipId == "member")
        #expect(stored.menuBarDisplay == .today)
        #expect(!stored.menuBarShowsSeconds)
        #expect(stored.menuBarUsesProjectColor)
        #expect(stored.workspace == workspace)
        #expect(stored.projectVisibility == visibility)
        #expect(client.load() == stored)
    }

    @Test func `legacy sidebar preferences preserve the selected view`() throws {
        let data = Data(#"{"navigation":{"account":{"destination":"history","showsSidebar":false}}}"#.utf8)
        let preferences = try JSONDecoder().decode(WorkspacePreferences.self, from: data)
        #expect(preferences.navigation["account"] == WorkspaceNavigation(destination: "history"))
        let encoded = try JSONEncoder().encode(preferences)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let navigation = try #require(object["navigation"] as? [String: [String: Any]])
        #expect(navigation["account"]?["showsSidebar"] == nil)
    }
}
