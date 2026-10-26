import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    private var visibilityProject: Project {
        Project(id: "project", name: "Website", color: "#18A970", isArchived: false, isBillable: true)
    }

    @Test func `hiding projects changes only picker choices and persists the preference`() async {
        var initial = state
        initial.data.projects = [visibilityProject]
        initial.data.entries = [entry(end: date, project: visibilityProject.id)]
        initial.projectId = visibilityProject.id
        let scope = initial.accountScope
        let stored = LockIsolated(ProjectVisibilityPreferences())
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.preferences.setProjectVisibility = { stored.setValue($0) }
        }
        await store.send(.view(.projectVisibilityChanged(visibilityProject.id, isVisible: false))) {
            $0.preferences.projectVisibility.setVisible(false, projectID: self.visibilityProject.id, in: scope)
        }
        await store.finish()
        #expect(stored.value == store.state.preferences.projectVisibility)
        #expect(store.state.selectableProjects.isEmpty)
        #expect(store.state.availableProjects == initial.availableProjects)
        #expect(store.state.projectId == visibilityProject.id)
        #expect(store.state.data == initial.data)
        #expect(store.state.recentEntries == initial.recentEntries)
        #expect(store.state.data.totals(at: date).week == 3600)

        await store.send(.view(.projectVisibilityChanged(visibilityProject.id, isVisible: true))) {
            $0.preferences.projectVisibility = ProjectVisibilityPreferences()
        }
        await store.finish()
        #expect(store.state.selectableProjects == initial.availableProjects)
        #expect(stored.value.hiddenIDs(in: scope).isEmpty)
    }

    @Test func `project visibility stays scoped to the instance user and organization`() throws {
        var initial = state
        initial.data.projects = [visibilityProject]
        initial.preferences.projectVisibility.setVisible(
            false,
            projectID: visibilityProject.id,
            in: initial.accountScope
        )
        #expect(initial.selectableProjects.isEmpty)
        var other = initial
        other.connection = try Connection(instance: "https://other.example.invalid", token: "test")
        #expect(other.selectableProjects == [visibilityProject])
        other = initial
        other.data.user = SolidtimeUser(id: "other", name: "Other", timezone: "UTC", weekStart: "monday")
        #expect(other.selectableProjects == [visibilityProject])
        other = initial
        other.data.memberships = [Membership(id: "member", organization: .init(id: "other", name: "Other"))]
        #expect(other.selectableProjects == [visibilityProject])
    }

    @Test func `opening an editor hides choices without removing the existing project`() async {
        var initial = state
        let existing = entry(end: date, project: visibilityProject.id)
        initial.data.projects = [visibilityProject]
        initial.data.entries = [existing]
        initial.preferences.projectVisibility.setVisible(
            false,
            projectID: visibilityProject.id,
            in: initial.accountScope
        )
        let editor = EntryEditorFeature.State(
            draft: EntryDraft(entry: existing), entry: existing, connection: connection,
            membership: member, projects: [visibilityProject], hiddenProjectIDs: [visibilityProject.id]
        )
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.system.openEntryEditor = { _ in }
        }
        await store.send(.view(.editTapped(existing))) { $0.destination = .editor(editor) }
        #expect(store.state.destination?.editor?.selectableProjects.isEmpty == true)
        #expect(store.state.destination?.editor?.draft.projectId == visibilityProject.id)
        await store.send(.destination(.dismiss)) { $0.destination = nil }
        await store.finish()
    }

    @Test func `bulk project visibility persists once and preserves other organizations`() async {
        var initial = state
        let second = Project(id: "second", name: "App", color: "#555555", isArchived: false, isBillable: false)
        initial.data.projects = [visibilityProject, second]
        let scope = initial.accountScope
        let projectIDs: Set<String> = [visibilityProject.id, second.id]
        initial.preferences.projectVisibility.setVisible(false, projectID: second.id, in: "other-organization")
        let persisted = LockIsolated<[ProjectVisibilityPreferences]>([])
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.preferences.setProjectVisibility = { value in persisted.withValue { $0.append(value) } }
        }
        await store.send(.view(.allProjectsVisibilityChanged(isVisible: false))) {
            $0.preferences.projectVisibility.setVisible(false, projectIDs: projectIDs, in: scope)
        }
        await store.finish()
        #expect(store.state.selectableProjects.isEmpty)
        #expect(persisted.value == [store.state.preferences.projectVisibility])

        await store.send(.view(.allProjectsVisibilityChanged(isVisible: true))) {
            $0.preferences.projectVisibility = initial.preferences.projectVisibility
        }
        await store.finish()
        #expect(store.state.selectableProjects == initial.availableProjects)
        #expect(persisted.value.count == 2)
        #expect(persisted.value.last == initial.preferences.projectVisibility)
    }
}
