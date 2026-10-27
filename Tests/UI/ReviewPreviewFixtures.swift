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
        let sample = AlphaSampleData(now: now)
        calendar = AlphaSampleData.user.calendar
        let today = calendar.startOfDay(for: now)
        var state = AppFeature.State()
        state.connection = try Connection(instance: AlphaSampleData.instanceAddress, token: AlphaSampleData.token)
        state.instanceAddress = AlphaSampleData.instanceAddress
        state.data = sample.session
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

    static func entry(
        _ id: String, start: Date, end: Date?, project: String? = "web",
        description: String = "Design review", organization: String = "studio"
    ) -> TimeEntry {
        AlphaSampleData.entry(id, start: start, end: end, project: project,
                              description: description, organization: organization)
    }

    func preview(
        _ name: String, _ screen: ReviewPreviewCase.Screen, change: (inout AppFeature.State) -> Void = { _ in }
    ) -> ReviewPreviewCase {
        var seed = state
        change(&seed)
        return ReviewPreviewCase(name, screen, state: seed)
    }

    func unlocked(_ state: inout AppFeature.State, surface: EarningsFeature.Surface) {
        state.preferences.workspace.earningsEnabled = true
        state.earnings.surface = surface
        state.earnings.settings = EarningsSettings(currency: "USD", hourlyRate: 25)
        state.earnings.savedSettings = state.earnings.settings
    }
}
