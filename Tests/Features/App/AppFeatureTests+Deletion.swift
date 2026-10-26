import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `deletion requires confirmation before calling any services`() async {
        var initial = state
        let target = entry(end: date)
        initial.data.entries = [target]
        let store = TestStore(initialState: initial) { AppFeature() }
        await store.send(.workspace(.delegate(.delete(target)))) {
            $0.destination = .deleteEntry(AppFeature.entryDeletionConfirmation(target))
        }
        await store.send(.refreshRequested(full: true))
        await store.send(.destination(.dismiss)) { $0.destination = nil }
        await store.finish()
    }

    @Test func `deletion rejects entries without an owned organization membership`() async {
        var initial = state
        let target = entry(end: date, organization: "another-organization")
        initial.data.entries = [target]
        let store = TestStore(initialState: initial) { AppFeature() }
        await store.send(.workspace(.delegate(.delete(target)))) {
            $0.error = String(localized: .thisEntryDoesntBelongToYourAccountRefreshAndTryAgain)
        }
        await store.finish()
    }

    @Test func `confirmed deletion reads the active timer first and preserves an unrelated running timer`() async {
        let calls = LockIsolated<[String]>([])
        var initial = state
        let target = entry(id: "completed", end: date)
        let running = entry(id: "running")
        initial.data.entries = [target, running]
        initial.data.active = running
        initial.destination = .deleteEntry(AppFeature.entryDeletionConfirmation(target))
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in calls.withValue { $0.append("read") }; return running }
            $0.solidtime.delete = { _, entry in
                #expect(entry == target)
                calls.withValue { $0.append("delete") }
            }
        }
        await store.send(.destination(.presented(.deleteEntry(.confirm(target))))) {
            $0.destination = nil
            $0.workID = self.id
        }
        await store.receive(.deleteResponse(id, target.id, .success(true))) {
            $0.workID = nil
            $0.data.entries = [running]
        }
        await store.finish()
        #expect(calls.value == ["read", "delete"])
    }

    @Test func `deleting a running entry removes it only after confirmed success`() async {
        var initial = state
        let target = entry()
        initial.data.entries = [target]
        initial.data.active = target
        initial.description = "Work"
        initial.reminder = .longRunning
        initial.destination = .deleteEntry(AppFeature.entryDeletionConfirmation(target))
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in target }
            $0.solidtime.delete = { _, _ in }
        }
        await store.send(.destination(.presented(.deleteEntry(.confirm(target))))) {
            $0.destination = nil
            $0.workID = self.id
        }
        await store.receive(.deleteResponse(id, target.id, .success(true))) {
            $0.workID = nil
            $0.data.entries = []
            $0.data.active = nil
            $0.description = ""
            $0.reminder = nil
        }
        await store.finish()
    }

    @Test func `a changed running timer prevents deletion without retrying a write`() async {
        var initial = state
        let target = entry()
        initial.data.entries = [target]
        initial.data.active = target
        initial.destination = .deleteEntry(AppFeature.entryDeletionConfirmation(target))
        let failure = Failure(AppError.message(String(localized: .entryDeleteChanged)))
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in nil }
        }
        await store.send(.destination(.presented(.deleteEntry(.confirm(target))))) {
            $0.destination = nil
            $0.workID = self.id
        }
        await store.receive(.deleteResponse(id, target.id, .failure(failure))) {
            $0.workID = nil
            $0.error = failure.message
        }
        await store.finish()
    }

    @Test func `delete failure preserves history and late delete responses are ignored`() async {
        var initial = state
        let target = entry(end: date)
        initial.data.entries = [target]
        initial.destination = .deleteEntry(AppFeature.entryDeletionConfirmation(target))
        let failure = Failure(AppError.http(403))
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in nil }
            $0.solidtime.delete = { _, _ in throw AppError.http(403) }
        }
        await store.send(.destination(.presented(.deleteEntry(.confirm(target))))) {
            $0.destination = nil
            $0.workID = self.id
        }
        await store.receive(.deleteResponse(id, target.id, .failure(failure))) {
            $0.workID = nil
            $0.error = failure.message
        }
        await store.send(.deleteResponse(UUID(1), target.id, .success(true)))
        await store.finish()
    }
}
