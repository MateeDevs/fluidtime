import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

@MainActor
@Suite(.serialized)
struct EntryEditorFeatureTests {
    private let connection: Connection

    init() throws {
        connection = try Connection(instance: "https://example.invalid", token: "test")
    }

    private let date = Date(timeIntervalSince1970: 1_792_620_000)
    private var entry: TimeEntry {
        TimeEntry(
            id: "entry", start: date.addingTimeInterval(-3600), end: nil, description: "Original",
            projectId: "old", taskId: "old-task", organizationId: "org", userId: "me", billable: false, tags: ["tag"]
        )
    }

    private var project: Project {
        Project(id: "new", name: "New", color: "#ffffff", isArchived: false, isBillable: true)
    }

    private var state: EntryEditorFeature.State {
        .init(
            draft: EntryDraft(entry: entry), entry: entry,
            connection: connection,
            membership: .init(id: "member", organization: .init(id: "org", name: "Test")), projects: [project]
        )
    }

    @Test func `moving project clears task and uses new billability`() async {
        let saved = TimeEntry(
            id: entry.id, start: entry.start, end: nil, description: "Updated", projectId: project.id,
            taskId: nil, organizationId: "org", userId: "me", billable: true, tags: ["tag"]
        )
        let store = TestStore(initialState: state) {
            EntryEditorFeature()
        } withDependencies: {
            $0.date.now = date
            $0.continuousClock = TestClock()
            let existing = entry
            $0.solidtime.activeEntry = { _ in existing }
            $0.solidtime.update = { _, update in
                #expect(update.memberId == "member")
                #expect(update.body["description"] as? String == "Updated")
                #expect(update.body["project_id"] as? String == "new")
                #expect(update.body["task_id"] is NSNull)
                #expect(update.body["billable"] as? Bool == true)
                #expect(update.body["tags"] == nil)
                return saved
            }
        }
        await store.send(.view(.binding(.set(\.draft.description, "Updated")))) { $0.draft.description = "Updated" }
        await store.send(.view(.binding(.set(\.draft.projectId, "new")))) { $0.draft.projectId = "new" }
        await store.send(.view(.saveTapped)) { $0.isSaving = true }
        await store.receive(.saveResponse(.success(saved))) { $0.isSaving = false }
        await store.receive(.delegate(.saved(saved)))
        await store.finish()
    }

    @Test func `failed save preserves the hidden assigned project and keeps the editor open`() async {
        let failure = Failure(AppError.http(503))
        var initial = state
        initial.hiddenProjectIDs = ["old"]
        let store = TestStore(initialState: initial) {
            EntryEditorFeature()
        } withDependencies: {
            $0.date.now = date
            $0.continuousClock = TestClock()
            let existing = entry
            $0.solidtime.activeEntry = { _ in existing }
            $0.solidtime.update = { _, update in
                #expect(update.body.count == 1) // Only description; preserve project, task, tags, and billability.
                throw AppError.http(503)
            }
        }
        await store.send(.view(.binding(.set(\.draft.description, "Unsaved change")))) {
            $0.draft.description = "Unsaved change"
        }
        await store.send(.view(.saveTapped)) { $0.isSaving = true }
        await store.receive(.saveResponse(.failure(failure))) {
            $0.isSaving = false
            $0.error = failure.message
        }
        #expect(store.state.draft.description == "Unsaved change")
        await store.finish()
    }

    @Test func `unavailable project fails before writing`() async {
        var initial = state
        initial.draft.projectId = "unavailable"
        let store = TestStore(initialState: initial) { EntryEditorFeature() } withDependencies: {
            $0.date.now = date
        }
        await store.send(.view(.saveTapped)) { $0.error = String(localized: .chooseAnAvailableProjectBeforeSaving) }
        await store.finish()
    }
}
