import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `timer shortcut stops the actual server timer even when local state is idle`() async {
        let running = entry()
        var stopped = running
        stopped = TimeEntry(
            id: running.id, start: running.start, end: date, description: running.description,
            projectId: running.projectId, taskId: running.taskId, organizationId: running.organizationId,
            userId: running.userId, billable: running.billable, tags: running.tags
        )
        let saved = stopped
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in running }
            $0.solidtime.update = { _, update in
                #expect(update.entry.id == running.id)
                #expect(update.memberId == "member")
                return saved
            }
        }
        await store.send(.interface(.toggleTimer)) { $0.workID = self.id }
        await store.receive(.timerStopped(id, saved)) { $0.data.applyStoppedTimer(saved, at: self.date) }
        await store.receive(.mutationResponse(id, .success(.saved(saved)))) { $0.workID = nil }
        await store.finish()
    }

    @Test func `timer shortcut starts a new work entry from the latest completed work`() async {
        let previous = entry(end: date.addingTimeInterval(-600), description: "Previous task")
        let created = TimeEntry(
            id: "new", start: date, end: nil, description: previous.description, projectId: nil,
            taskId: nil, organizationId: "org", userId: "me", billable: false, tags: []
        )
        var initial = state
        initial.data.entries = [previous]
        initial.preferences.workspace.timerFeedback = true
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.uuid = .constant(id)
            $0.date.now = date
            $0.continuousClock = TestClock()
            $0.solidtime.activeEntry = { _ in nil }
            $0.solidtime.create = { _, _, description, project, _ in
                #expect(description == "Previous task")
                #expect(project == nil)
                return created
            }
            $0.system.showTimerFeedback = { #expect($0 == .started(created)) }
        }
        await store.send(.interface(.toggleTimer)) { $0.workID = self.id }
        await store.receive(.mutationResponse(id, .success(.saved(created)))) {
            $0.workID = nil
            $0.data.apply(created, at: self.date)
        }
        await store.finish()
    }

    @Test func `reminders never change entries and are shown once per running entry`() async {
        var initial = state
        let running = entry()
        initial.data.active = running
        initial.preferences.workspace.idleReminderMinutes = 5
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.system.showTimerFeedback = { #expect($0 == .idleReminder) }
        }
        await store.send(.reminderInputReceived(running.id, 600)) {
            $0.remindedEntryId = running.id
            $0.remindedKinds = [.idle]
            $0.reminder = .idle
        }
        await store.finish()
        await store.send(.view(.dismissReminder)) { $0.reminder = nil }
        await store.send(.reminderInputReceived(running.id, 900))
        await store.finish()
    }
}
