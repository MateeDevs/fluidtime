import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `presentation prevents conflicting account changes and refreshes`() async {
        var initial = state
        let existing = entry(end: date)
        initial.data.entries = [existing]
        let store = TestStore(initialState: initial) { AppFeature() }
        await store.send(.view(.disconnectTapped)) {
            $0.destination = .disconnect(AppFeature.disconnectConfirmation())
        }
        await store.send(.view(.editTapped(existing)))
        await store.send(.view(.connectTapped))
        await store.send(.refreshRequested(full: false))
        await store.send(.destination(.dismiss)) { $0.destination = nil }
        await store.finish()
    }

    @Test func `editor cancel dismisses through parent presentation`() async {
        var initial = state
        let existing = entry(end: date)
        initial.data.entries = [existing]
        let editor = EntryEditorFeature.State(
            draft: EntryDraft(entry: existing), entry: existing,
            connection: connection, membership: member, projects: []
        )
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.system.openEntryEditor = { _ in }
        }
        await store.send(.view(.editTapped(existing))) { $0.destination = .editor(editor) }
        await store.send(.destination(.presented(.editor(.view(.cancelTapped)))))
        await store.receive(.destination(.dismiss)) { $0.destination = nil }
        await store.finish()
    }

    @Test func `editor save updates parent and dismisses`() async {
        var initial = state
        let existing = entry(end: date)
        let saved = TimeEntry(
            id: existing.id, start: existing.start, end: date, description: "Updated",
            projectId: nil, taskId: nil, organizationId: "org", userId: "me", billable: false, tags: []
        )
        initial.data.entries = [existing]
        let editor = EntryEditorFeature.State(
            draft: EntryDraft(entry: existing), entry: existing,
            connection: connection, membership: member, projects: []
        )
        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.system.openEntryEditor = { _ in }
            $0.solidtime.activeEntry = { _ in nil }
            $0.solidtime.update = { _, _ in saved }
        }
        await store.send(.view(.editTapped(existing))) { $0.destination = .editor(editor) }
        await store.send(.destination(.presented(.editor(.view(.saveTapped))))) {
            var saving = editor
            saving.isSaving = true
            $0.destination = .editor(saving)
        }
        await store.receive(.destination(.presented(.editor(.saveResponse(.success(saved)))))) {
            $0.destination = .editor(editor)
        }
        await store.receive(.destination(.presented(.editor(.delegate(.saved(saved)))))) {
            $0.data.apply(saved, at: self.date)
            $0.destination = nil
        }
        await store.finish()
    }

    @Test func `shutdown cancels editor and ignores non cooperative response`() async throws {
        var initial = state
        let existing = entry(end: date)
        initial.data.entries = [existing]
        let continuation = LockIsolated<CheckedContinuation<TimeEntry, Never>?>(nil)
        let editor = EntryEditorFeature.State(
            draft: EntryDraft(entry: existing), entry: existing,
            connection: connection, membership: member, projects: []
        )
        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.system.openEntryEditor = { _ in }
            $0.solidtime.activeEntry = { _ in nil }
            $0.solidtime.update = { _, _ in
                await withCheckedContinuation { continuation.setValue($0) }
            }
        }
        await store.send(.view(.editTapped(existing))) { $0.destination = .editor(editor) }
        await store.send(.destination(.presented(.editor(.view(.saveTapped))))) {
            var saving = editor
            saving.isSaving = true
            $0.destination = .editor(saving)
        }
        let pending = try #require(continuation.value)
        await store.send(.interface(.shutdown)) { $0.destination = nil }
        pending.resume(returning: existing)
        await Task.megaYield()
        await store.finish()
    }
}
