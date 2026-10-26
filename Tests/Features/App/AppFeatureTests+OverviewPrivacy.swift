import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test(arguments: [true, false], [WorkspaceFeature.Tab.history, .analysis, .daily])
    func `leaving overview conceals values and cancels pending private access`(
        _ pending: Bool, _ tab: WorkspaceFeature.Tab
    ) async {
        var initial = state
        if pending {
            initial.earnings.pendingSurface = .preview
            initial.earnings.operation = id
        } else {
            initial.earnings.surface = .preview
            initial.earnings.settings = EarningsSettings(currency: "USD", hourlyRate: 25)
            initial.earnings.savedSettings = initial.earnings.settings
        }
        let scope = initial.accountScope
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.preferences.setWorkspace = { _ in }
        }
        await store.send(.workspace(.view(.binding(.set(\.tab, tab))))) {
            $0.workspace.tab = tab
            $0.preferences.workspace.navigation[scope] = WorkspaceNavigation(destination: tab.rawValue)
        }
        await store.receive(.earnings(.interface(.conceal(.preview)))) {
            $0.earnings = EarningsFeature.State(accountScope: $0.accountScope)
        }
        await store.send(.earnings(.unlockResponse(id, .success(EarningsSettings(currency: "USD", hourlyRate: 25)))))
        await store.finish()
    }

    @Test func `earnings stays off for existing preferences and persists explicit opt in`() throws {
        let legacy = try JSONDecoder().decode(WorkspacePreferences.self, from: Data("{}".utf8))
        #expect(!legacy.earningsEnabled)
        var enabled = legacy
        enabled.earningsEnabled = true
        let restored = try JSONDecoder().decode(WorkspacePreferences.self, from: JSONEncoder().encode(enabled))
        #expect(restored.earningsEnabled)
    }

    @Test(arguments: [true, false])
    func `disabling earnings immediately clears private access and ignores late unlock`(_ pending: Bool) async {
        let saved = LockIsolated<WorkspacePreferences?>(nil)
        var initial = state
        initial.preferences.workspace.earningsEnabled = true
        initial.earnings.accountScope = initial.accountScope
        if pending {
            initial.earnings.operation = id
            initial.earnings.pendingSurface = .preview
        } else {
            initial.earnings.surface = .settings
            initial.earnings.settings = EarningsSettings(currency: "USD", hourlyRate: 25)
            initial.earnings.savedSettings = initial.earnings.settings
        }
        var disabled = initial.preferences.workspace
        disabled.earningsEnabled = false
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.preferences.setWorkspace = { saved.setValue($0) }
        }
        await store.send(.view(.workspacePreferencesChanged(disabled))) {
            $0.preferences.workspace = disabled
            $0.earnings = EarningsFeature.State(accountScope: $0.accountScope)
        }
        await store.receive(.earnings(.interface(.lock)))
        await store.send(.earnings(.unlockResponse(id, .success(EarningsSettings(currency: "USD", hourlyRate: 25)))))
        await store.finish()
        #expect(saved.value?.earningsEnabled == false)
    }
}
