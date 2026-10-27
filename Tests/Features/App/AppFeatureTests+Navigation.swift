import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import SwiftUI
import Testing

extension AppFeatureTests {
    @Test(arguments: WorkspaceFeature.Tab.allCases)
    func `navigation changes persist only in the current account scope`(_ tab: WorkspaceFeature.Tab) async {
        let saved = LockIsolated<WorkspacePreferences?>(nil)
        let scope = state.accountScope
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.preferences.setWorkspace = { saved.setValue($0) }
        }
        await store.send(.workspace(.view(.binding(.set(\.tab, tab))))) {
            $0.workspace.tab = tab
            $0.preferences.workspace.navigation[scope] = WorkspaceNavigation(
                destination: tab.rawValue,
                showsSidebar: true
            )
        }
        await store.finish()
        #expect(saved.value?.navigation == [scope: WorkspaceNavigation(destination: tab.rawValue, showsSidebar: true)])
    }

    @Test func `sidebar toggles persist per account and restore on reopening`() async {
        let scope = state.accountScope
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.preferences.setWorkspace = { preferences in
                #expect(preferences.navigation[scope]?.showsSidebar == false)
            }
        }
        await store.send(.workspace(.view(.toggleSidebar))) {
            $0.workspace.columnVisibility = .detailOnly
            $0.preferences.workspace.navigation[scope] = WorkspaceNavigation(
                destination: "overview", showsSidebar: false
            )
        }
        await store.finish()

        var restored = state
        restored.workspace.calendar = user.calendar
        restored.workspace.customStart = date
        restored.preferences.workspace = store.state.preferences.workspace
        let reopened = TestStore(initialState: restored) { AppFeature() }
        await reopened.send(.workspace(.view(.appeared(scope, user.calendar)))) {
            $0.workspace.accountScope = scope
            $0.workspace.columnVisibility = .detailOnly
        }
        await reopened.finish()
    }

    @Test(arguments: [true, false], WorkspaceFeature.Tab.allCases)
    func `workspace restores navigation for the matching account only`(
        _ matches: Bool, _ tab: WorkspaceFeature.Tab
    ) async {
        var initial = state
        let scope = initial.accountScope
        let calendar = user.calendar
        initial.workspace.calendar = calendar
        initial.workspace.customStart = date
        initial.preferences.workspace.navigation[matches ? scope : "another-account"] = WorkspaceNavigation(
            destination: tab.rawValue
        )
        let store = TestStore(initialState: initial) { AppFeature() }
        await store.send(.workspace(.view(.appeared(scope, calendar)))) {
            $0.workspace.accountScope = scope
            if matches {
                $0.workspace.tab = tab
            }
        }
    }
}
