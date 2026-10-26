import Foundation

struct AppPreferences: Equatable, Sendable {
    var instance = "https://app.solidtime.io"
    var membershipId = ""
    var menuBarDisplay = MenuBarDisplay.elapsed
    var menuBarShowsSeconds = true
    var menuBarUsesProjectColor = false
    var workspace = WorkspacePreferences()
    var projectVisibility = ProjectVisibilityPreferences()
}
