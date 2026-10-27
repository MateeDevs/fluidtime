import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `editing from the panel opens an independent window`() async {
        var initial = state
        let existing = entry(end: date)
        initial.data.entries = [existing]
        initial.isMenuBarPresented = true
        let anchor = "tracker.panel.\(existing.id)"
        let opened = LockIsolated<String?>(nil)
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.system.openEntryEditor = { opened.setValue($0) }
            $0.system.setDockIconVisible = { #expect($0) }
        }
        await store.send(.view(.editTapped(existing, anchor: anchor))) {
            $0.destination = .editor(EntryEditorFeature.State(
                draft: EntryDraft(entry: existing), entry: existing,
                connection: self.connection, membership: self.member, projects: [], presentationAnchor: anchor
            ))
        }
        await store.finish()
        #expect(opened.value == anchor)
        #expect(store.state.isMenuBarPresented)
        await store.send(.interface(.editorPresentationChanged(true))) { $0.isEditorPresented = true }
        #expect(store.state.showsDockIcon)
        await store.finish()
    }

    @Test func `closing an editor window dismisses its draft and allows refresh again`() async {
        var initial = state
        let existing = entry(end: date)
        initial.isEditorPresented = true
        initial.destination = .editor(EntryEditorFeature.State(
            draft: EntryDraft(entry: existing), entry: existing,
            connection: connection, membership: member, projects: []
        ))
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.system.setDockIconVisible = { #expect(!$0) }
        }
        await store.send(.interface(.editorPresentationChanged(false))) { $0.isEditorPresented = false }
        await store.receive(.destination(.dismiss)) { $0.destination = nil }
        await store.finish()
    }

    @Test func `reopening the editor restores the Dock while the main window stays closed`() async {
        let dock = LockIsolated<[Bool]>([])
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.system.setDockIconVisible = { visible in dock.withValue { $0.append(visible) } }
        }
        await store.send(.interface(.editorPresentationChanged(true))) { $0.isEditorPresented = true }
        await store.finish()
        await store.send(.interface(.editorPresentationChanged(false))) { $0.isEditorPresented = false }
        await store.finish()
        await store.send(.interface(.editorPresentationChanged(true))) { $0.isEditorPresented = true }
        await store.finish()
        #expect(dock.value == [true, false, true])
    }

    @Test func `menu shortcut can toggle while the standalone editor saves`() async {
        var initial = state
        let existing = entry(end: date)
        initial.isMenuBarPresented = true
        var editor = EntryEditorFeature.State(
            draft: EntryDraft(entry: existing), entry: existing,
            connection: connection, membership: member, projects: []
        )
        editor.isSaving = true
        initial.destination = .editor(editor)
        let store = TestStore(initialState: initial) { AppFeature() }
        await store.send(.interface(.toggleMenuBar)) { $0.isMenuBarPresented = false }
        await store.send(.interface(.menuBarPresentationChanged(true))) { $0.isMenuBarPresented = true }
        await store.send(.interface(.menuBarPresentationChanged(false))) { $0.isMenuBarPresented = false }
        await store.finish()
    }
}
