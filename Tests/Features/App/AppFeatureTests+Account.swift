import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `disconnect removes credentials without stopping timer`() async {
        var initial = state
        initial.data.active = entry()
        initial.apiKey = "unsaved-key"
        let expectedURL = connection.instance
        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.continuousClock = TestClock()
            $0.credentials.delete = { #expect($0 == expectedURL) }
            // Every API operation remains unimplemented.
        }
        await store.send(.view(.disconnectTapped)) {
            $0.destination = .disconnect(AppFeature.disconnectConfirmation())
        }
        await store.send(.destination(.presented(.disconnect(.confirm)))) {
            $0.destination = nil
            $0.workID = self.id
        }
        await store.receive(.disconnectResponse(id, .success(true))) {
            $0.workID = nil
            $0.connection = nil
            $0.data = SessionData()
            $0.earnings = EarningsFeature.State()
            $0.apiKey = ""
        }
        await store.finish()
    }

    @Test(arguments: [MenuBarDisplay.indicator, .today])
    func `menu bar preference persists through dependency`(_ display: MenuBarDisplay) async {
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.preferences.setMenuBarDisplay = { #expect($0 == display) }
        }
        await store.send(.view(.binding(.set(\.menuBarDisplay, display)))) { $0.menuBarDisplay = display }
        await store.finish()
    }

    @Test func `failed connection preserves existing session`() async {
        var initial = state
        initial.instanceAddress = "https://new.example.invalid"
        initial.apiKey = "new-token"
        let failure = Failure(AppError.http(401))
        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.user = { _ in throw AppError.http(401) }
            $0.solidtime.memberships = { _ in [] }
            // Credentials aren't saved until every required read succeeds.
        }
        await store.send(.view(.connectTapped)) { $0.workID = self.id }
        await store.receive(.syncResponse(id, .failure(failure))) {
            $0.workID = nil
            $0.error = failure.message
        }
        #expect(store.state.connection == connection)
        await store.finish()
    }

    @Test func `selecting organization scopes refresh and keeps other organization timer`() async throws {
        let other = Membership(id: "member-2", organization: .init(id: "org-2", name: "Other"))
        let memberships = [member, other]
        let user = user
        let active = entry()
        var initial = state
        initial.data.memberships = memberships
        initial.data.entries = [active]
        initial.data.active = active
        var refreshed = initial.data
        refreshed.entries = []
        refreshed.selectedMembershipId = other.id
        refreshed.lastFullSync = date
        refreshed.syncedWeekStart = try #require(user.calendar.dateInterval(of: .weekOfYear, for: date)?.start)
        let reply = AppFeature.SyncResponse(connection: connection, data: refreshed, isNewConnection: false)
        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.preferences.setMembership = { #expect($0 == other.id) }
            $0.solidtime.user = { _ in user }
            $0.solidtime.memberships = { _ in memberships }
            $0.solidtime.activeEntry = { _ in active }
            $0.solidtime.projects = { _, organization in
                #expect(organization == other.organization.id)
                return []
            }
            $0.solidtime.entries = { _, membership, since in
                #expect(membership == other)
                #expect(since == nil)
                return []
            }
        }
        await store.send(.view(.selectMembership(other.id))) {
            $0.data.selectedMembershipId = other.id
            $0.data.clearEntries()
            $0.preferences.membershipId = other.id
            $0.earnings = EarningsFeature.State(accountScope: $0.accountScope)
            $0.workID = self.id
        }
        await store.receive(.syncResponse(id, .success(reply))) {
            $0.data = refreshed
            $0.description = active.description ?? ""
            $0.workID = nil
        }
        #expect(store.state.activeInAnotherOrganization)
        #expect(store.state.data.entries.isEmpty)
        await store.finish()
    }
}
