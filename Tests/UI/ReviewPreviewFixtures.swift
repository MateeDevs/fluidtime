import ComposableArchitecture
@testable import FluidtimeCore
import Foundation

struct ReviewPreviewFixtures {
    static let longDescription = "Review navigation, onboarding, accessibility, "
        + "and account settings with the product team"
    let now = Date()
    let calendar: Calendar
    let state: AppFeature.State

    init() throws {
        calendar = try AnalyticsFixtures.calendar("Europe/Prague")
        var state = AppFeature.State()
        state.connection = try Connection(instance: "https://example.invalid", token: "fictional-preview")
        state.instanceAddress = "https://example.invalid"
        state.data.user = SolidtimeUser(
            id: "preview-user",
            name: "Alex Morgan",
            timezone: "Europe/Prague",
            weekStart: "monday"
        )
        state.data.memberships = [
            Membership(id: "member", organization: .init(id: "studio", name: "Design studio")),
            Membership(id: "other-member", organization: .init(id: "other", name: "Community projects"))
        ]
        state.data.selectedMembershipId = "member"
        state.data.projects = [
            Project(id: "web", name: "Website redesign", color: "#18A970", isArchived: false, isBillable: true),
            Project(id: "app", name: "Mobile application", color: "#9C6ADE", isArchived: false, isBillable: true),
            Project(id: "internal", name: "Internal projects", color: "#F79C42", isArchived: false, isBillable: false)
        ]
        let today = calendar.startOfDay(for: now)
        state.data.entries = Self.entries(projects: state.data.projects, calendar: calendar, now: now)
        state.data.active = state.data.entries.first
        state.data.lastSynced = now
        state.data.lastFullSync = now
        state.earnings.accountScope = state.accountScope
        state.workspace.accountScope = state.accountScope
        state.workspace.calendar = calendar
        state.workspace.customStart = calendar.date(byAdding: .day, value: -14, to: today)!
        state.workspace.customEnd = now
        state.workspace.history.start = state.workspace.customStart
        state.workspace.history.end = now
        state.generalSettings.status = .disabled
        state.generalSettings.updates.status = UpdateStatus()
        self.state = state
    }

    private static func entries(projects: [Project], calendar: Calendar, now: Date) -> [TimeEntry] {
        let today = calendar.startOfDay(for: now)
        var entries: [TimeEntry] = []
        for day in 1 ... 35 {
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            for (index, hours) in [(9, 3.0), (13, 2.0), (15, 1.5)] {
                let start = calendar.date(byAdding: .hour, value: index, to: date)!
                entries.append(Self.entry("day-\(day)-\(index)", start: start,
                                          end: start.addingTimeInterval(hours * 3600),
                                          project: projects[day % 3].id,
                                          description: ["Design review", "Navigation and onboarding", "Weekly planning",
                                                        "Prototype updates", "Project administration",
                                                        "Accessibility review",
                                                        "Development planning"][day % 7]))
            }
        }
        let running = Self.entry("running", start: now.addingTimeInterval(-2700), end: nil,
                                 project: "web", description: "Design review")
        return [running] + entries.sorted { $0.start > $1.start }
    }

    static func entry(
        _ id: String, start: Date, end: Date?, project: String? = "web",
        description: String = "Design review", organization: String = "studio"
    ) -> TimeEntry {
        TimeEntry(id: id, start: start, end: end, description: description, projectId: project, taskId: nil,
                  organizationId: organization, userId: "preview-user", billable: project != "internal", tags: [])
    }

    func preview(
        _ name: String, _ screen: ReviewPreviewCase.Screen, change: (inout AppFeature.State) -> Void = { _ in }
    ) -> ReviewPreviewCase {
        var seed = state
        change(&seed)
        return ReviewPreviewCase(name, screen, state: seed)
    }

    func unlocked(_ state: inout AppFeature.State, surface: EarningsFeature.Surface) {
        state.earnings.surface = surface
        state.earnings.settings = EarningsSettings(currency: "USD", hourlyRate: 25)
        state.earnings.savedSettings = state.earnings.settings
    }
}
