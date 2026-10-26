import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `start checks active and applies created entry`() async {
        let created = entry()
        let expectedMember = member
        let now = date
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in nil }
            $0.solidtime.create = { _, member, description, project, date in
                #expect(member == expectedMember)
                #expect(description == "")
                #expect(project == nil)
                #expect(date == now)
                return created
            }
        }
        await store.send(.view(.startTapped)) { $0.workID = self.id }
        await store.receive(.mutationResponse(id, .success(.saved(created)))) {
            $0.workID = nil
            $0.data.apply(created, at: self.date)
        }
        await store.finish()
    }

    @Test func `existing remote timer prevents creation`() async {
        let active = entry(id: "remote")
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in active }
            // create remains unimplemented: calling it fails this test.
        }
        await store.send(.view(.startTapped)) { $0.workID = self.id }
        await store.receive(.mutationResponse(id, .success(.existingTimer(active)))) {
            $0.workID = nil
            $0.data.apply(active, at: self.date)
            $0.error = String(localized: .youAlreadyHaveARunningTimerStopItBeforeStartingAnother)
        }
        await store.finish()
    }

    @Test func `changed remote timer prevents stop`() async {
        var initial = state
        initial.data.active = entry()
        let replacement = entry(id: "replacement")
        let failure = Failure(
            AppError.message(String(localized: .yourRunningTimerChangedOnSolidtimeRefreshBeforeStoppingIt))
        )
        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in replacement }
        }
        await store.send(.view(.stopTapped)) { $0.workID = self.id }
        await store.receive(.mutationResponse(id, .failure(failure))) {
            $0.workID = nil
            $0.error = failure.message
        }
        #expect(store.state.active?.id == "entry")
        await store.finish()
    }

    @Test func `progress waits two seconds and failure retains data`() async {
        let clock = TestClock()
        let failure = Failure(AppError.http(503))
        var initial = state
        initial.data.entries = [entry(end: date)]
        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = clock
            $0.solidtime.activeEntry = { _ in
                try await clock.sleep(for: .seconds(3))
                throw AppError.http(503)
            }
        }
        await store.send(.view(.startTapped)) { $0.workID = self.id }
        await clock.advance(by: .seconds(1))
        #expect(!store.state.showsProgress)
        await clock.advance(by: .seconds(1))
        await store.receive(.showProgress(id)) { $0.showsProgress = true }
        await clock.advance(by: .seconds(1))
        await store.receive(.mutationResponse(id, .failure(failure))) {
            $0.workID = nil
            $0.showsProgress = false
            $0.error = failure.message
        }
        #expect(store.state.data.entries == initial.data.entries)
        await store.finish()
    }

    @Test func `recent timer starts atomically and rejects another tap`() async throws {
        let continuation = LockIsolated<CheckedContinuation<TimeEntry?, Never>?>(nil)
        let recent = entry(id: "recent", end: date)
        let created = entry(id: "created")
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in
                await withCheckedContinuation { continuation.setValue($0) }
            }
            $0.solidtime.create = { _, _, description, _, _ in
                #expect(description == recent.description)
                return created
            }
        }
        await store.send(.view(.startRecent(recent))) {
            $0.description = "Work"
            $0.workID = self.id
        }
        await store.send(.view(.startRecent(entry(id: "another", end: date, description: "Different work"))))
        let pending = try #require(continuation.value)
        pending.resume(returning: nil)
        await store.receive(.mutationResponse(id, .success(.saved(created)))) {
            $0.data.apply(created, at: self.date)
            $0.workID = nil
        }
        await store.finish()
    }

    @Test func `stale work response cannot overwrite current state`() async {
        var initial = state
        initial.workID = UUID(1)
        let store = TestStore(initialState: initial) { AppFeature() }
        await store.send(.mutationResponse(id, .success(.saved(entry()))))
        await store.send(.showProgress(id))
        await store.finish()
    }

    @Test func `cancellation during preflight prevents creating an entry`() async throws {
        let continuation = LockIsolated<CheckedContinuation<TimeEntry?, Never>?>(nil)
        let store = TestStore(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in
                await withCheckedContinuation { continuation.setValue($0) }
            }
            // create remains unimplemented and must never be called after cancellation.
        }
        await store.send(.view(.startTapped)) { $0.workID = self.id }
        let pending = try #require(continuation.value)
        await store.send(.interface(.shutdown)) { $0.workID = nil }
        pending.resume(returning: nil)
        await Task.megaYield()
        await store.finish()
    }
}
