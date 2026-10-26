import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

@MainActor
@Suite(.serialized)
struct AppFeatureTests {
    let date = Date(timeIntervalSince1970: 1_792_620_000)
    let id = UUID(0)
    let connection: Connection

    init() throws {
        connection = try Connection(instance: "https://example.invalid", token: "test")
    }

    var member: Membership {
        Membership(id: "member", organization: .init(id: "org", name: "Test"))
    }

    var user: SolidtimeUser {
        SolidtimeUser(id: "me", name: "Alex", timezone: "Europe/Prague", weekStart: "monday")
    }

    func entry(
        id: String = "entry", end: Date? = nil, project: String? = nil, description: String = "Work",
        organization: String = "org"
    ) -> TimeEntry {
        TimeEntry(
            id: id, start: date.addingTimeInterval(-3600), end: end, description: description, projectId: project,
            taskId: nil, organizationId: organization, userId: "me", billable: false, tags: []
        )
    }

    var state: AppFeature.State {
        var state = AppFeature.State()
        state.preferences.workspace.timerFeedback = false
        state.connection = connection
        state.data.user = user
        state.data.memberships = [member]
        state.data.selectedMembershipId = member.id
        state.data.lastSynced = date
        state.earnings.accountScope = state.accountScope
        return state
    }
}
