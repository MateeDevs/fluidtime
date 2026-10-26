import Foundation

/// UserDefaults is thread-safe. This adapter holds only an immutable reference to it.
final class PreferencesStore: @unchecked Sendable {
    private let defaults: UserDefaults

    private enum Key {
        static let instance = "instanceAddress"
        static let membership = "membershipId"
        static let menuBarShowsSeconds = "menuBarShowsSeconds"
        static let menuBarUsesProjectColor = "menuBarUsesProjectColor"
        static let menuBarDisplay = "menuBarDisplay"
        static let workspace = "workspacePreferences"
        static let projectVisibility = "projectVisibility"
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func load() -> AppPreferences {
        AppPreferences(
            instance: defaults.string(forKey: Key.instance) ?? "https://app.solidtime.io",
            membershipId: defaults.string(forKey: Key.membership) ?? "",
            menuBarDisplay: MenuBarDisplay(rawValue: defaults.string(forKey: Key.menuBarDisplay) ?? "") ?? .elapsed,
            menuBarShowsSeconds: defaults.object(forKey: Key.menuBarShowsSeconds) as? Bool ?? true,
            menuBarUsesProjectColor: defaults.bool(forKey: Key.menuBarUsesProjectColor),
            workspace: defaults.data(forKey: Key.workspace).flatMap {
                try? JSONDecoder().decode(WorkspacePreferences.self, from: $0)
            } ?? WorkspacePreferences(),
            projectVisibility: defaults.data(forKey: Key.projectVisibility).flatMap {
                try? JSONDecoder().decode(ProjectVisibilityPreferences.self, from: $0)
            } ?? ProjectVisibilityPreferences()
        )
    }

    func setInstance(_ address: String) {
        defaults.set(address, forKey: Key.instance)
    }

    func setMembership(_ id: String) {
        defaults.set(id, forKey: Key.membership)
    }

    func setMenuBarUsesProjectColor(_ usesProjectColor: Bool) {
        defaults.set(usesProjectColor, forKey: Key.menuBarUsesProjectColor)
    }

    func setMenuBarShowsSeconds(_ showsSeconds: Bool) {
        defaults.set(showsSeconds, forKey: Key.menuBarShowsSeconds)
    }

    func setMenuBarDisplay(_ display: MenuBarDisplay) {
        defaults.set(display.rawValue, forKey: Key.menuBarDisplay)
    }

    func setProjectVisibility(_ visibility: ProjectVisibilityPreferences) {
        guard let data = try? JSONEncoder().encode(visibility) else { return }
        defaults.set(data, forKey: Key.projectVisibility)
    }

    func setWorkspace(_ workspace: WorkspacePreferences) {
        guard let data = try? JSONEncoder().encode(workspace) else { return }
        defaults.set(data, forKey: Key.workspace)
    }
}
