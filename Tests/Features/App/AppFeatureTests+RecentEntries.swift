import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test(arguments: [false, true])
    func `recent entry stops remote timer before creating replacement`(inAnotherOrganization: Bool) async {
        let otherMember = Membership(id: "other-member", organization: .init(id: "other", name: "Other"))
        let stopMember = inAnotherOrganization ? otherMember : member
        let active = entry(id: "remote", organization: stopMember.organization.id)
        let stopped = entry(id: active.id, end: date, organization: active.organizationId)
        let recent = entry(id: "recent", end: date, project: "project", description: "Recent work")
        let project = Project(id: "project", name: "Project", color: "#ffffff", isArchived: false, isBillable: true)
        let calls = LockIsolated<[String]>([])
        let expectedMember = member
        let now = date
        let created = entry(id: "created", project: project.id, description: "Recent work")
        let initial = recentSwitchState(project: project, otherMember: otherMember)
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in active }
            $0.solidtime.update = { _, update in
                #expect(update == EntryUpdate(entry: active, memberId: stopMember.id, change: .stop(now)))
                calls.withValue { $0.append("stop") }
                return stopped
            }
            $0.solidtime.create = { _, membership, description, selectedProject, start in
                #expect(calls.value == ["stop"])
                #expect(membership == expectedMember)
                #expect(description == recent.description)
                #expect(selectedProject == project)
                #expect(start == now)
                calls.withValue { $0.append("create") }
                return created
            }
        }
        await store.send(.view(.startRecent(recent))) {
            $0.description = "Recent work"
            $0.projectId = project.id
            $0.workID = self.id
        }
        await store.receive(.timerStopped(id, stopped)) {
            $0.data.active = nil
            $0.data.entries = inAnotherOrganization ? [] : [stopped]
            $0.data.lastFullSync = nil
        }
        #expect(store.state.isBusy)
        await store.receive(.mutationResponse(id, .success(.saved(created)))) {
            $0.data.apply(created, at: self.date)
            $0.workID = nil
        }
        #expect(calls.value == ["stop", "create"])
        await store.finish()
    }

    @Test func `failed stop prevents starting recent entry`() async {
        let active = entry()
        let recent = entry(id: "recent", end: date)
        let failure = Failure(AppError.http(503))
        var initial = state
        initial.data.active = active
        initial.data.entries = [active]
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in active }
            $0.solidtime.update = { _, _ in throw AppError.http(503) }
            // Creating an entry remains unimplemented and must never be attempted.
        }
        await store.send(.view(.startRecent(recent))) {
            $0.description = "Work"
            $0.workID = self.id
        }
        await store.receive(.mutationResponse(id, .failure(failure))) {
            $0.workID = nil
            $0.error = failure.message
        }
        #expect(store.state.data == initial.data)
        await store.finish()
    }

    @Test func `failed replacement creation retains confirmed stop`() async {
        let active = entry()
        let stopped = entry(end: date)
        let recent = entry(id: "recent", end: date)
        let failure = Failure(AppError.http(503))
        var initial = state
        initial.data.active = active
        initial.data.entries = [active]
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in active }
            $0.solidtime.update = { _, _ in stopped }
            $0.solidtime.create = { _, _, _, _, _ in throw AppError.http(503) }
        }
        await store.send(.view(.startRecent(recent))) {
            $0.description = "Work"
            $0.workID = self.id
        }
        await store.receive(.timerStopped(id, stopped)) { $0.data.apply(stopped, at: self.date) }
        await store.receive(.mutationResponse(id, .failure(failure))) {
            $0.workID = nil
            $0.error = failure.message
        }
        #expect(store.state.active == nil)
        #expect(store.state.data.entries == [stopped])
        await store.finish()
    }

    @Test func `cancellation during stop prevents replacement creation`() async throws {
        let continuation = LockIsolated<CheckedContinuation<TimeEntry, Never>?>(nil)
        let active = entry()
        let stopped = entry(end: date)
        let recent = entry(id: "recent", end: date)
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in active }
            $0.solidtime.update = { _, _ in
                await withCheckedContinuation { continuation.setValue($0) }
            }
            // Creating an entry remains unimplemented and must never happen after cancellation.
        }
        await store.send(.view(.startRecent(recent))) {
            $0.description = "Work"
            $0.workID = self.id
        }
        let pending = try #require(continuation.value)
        await store.send(.interface(.shutdown)) { $0.workID = nil }
        pending.resume(returning: stopped)
        await Task.megaYield()
        await store.finish()
    }

    private func recentSwitchState(project: Project, otherMember: Membership) -> AppFeature.State {
        var initial = state
        initial.data.active = entry(id: "stale")
        initial.data.entries = [entry(id: "stale")]
        initial.data.memberships.append(otherMember)
        initial.data.lastFullSync = date
        initial.data.projects = [project]
        return initial
    }
}
