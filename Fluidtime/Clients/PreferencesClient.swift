import ComposableArchitecture
import Foundation

@DependencyClient
struct PreferencesClient: Sendable {
    var load: @Sendable () -> AppPreferences = { .init() }
    var setInstance: @Sendable (String) -> Void
    var setMembership: @Sendable (String) -> Void
    var setMenuBarUsesProjectColor: @Sendable (Bool) -> Void
    var setMenuBarShowsSeconds: @Sendable (Bool) -> Void
    var setMenuBarDisplay: @Sendable (MenuBarDisplay) -> Void
    var setWorkspace: @Sendable (WorkspacePreferences) -> Void
    var setProjectVisibility: @Sendable (ProjectVisibilityPreferences) -> Void
}

extension PreferencesClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var preferences: PreferencesClient {
        get { self[PreferencesClient.self] }
        set { self[PreferencesClient.self] = newValue }
    }
}
