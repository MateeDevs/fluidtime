import AppKit
import ComposableArchitecture
@testable import FluidtimeCore

extension ReviewPreviewFixtures {
    /// Content-only captures avoid native tab chrome that a hidden bitmap host cannot composite.
    func readmeCases() -> [ReviewPreviewCase] {
        var general = preview("readme-general", .generalSettingsContent)
        general.size = NSSize(width: 540, height: 360)
        var menuBar = preview("readme-menu-bar", .menuBarSettingsContent)
        menuBar.size = NSSize(width: 540, height: 225)
        var analysis = preview("readme-analysis", .main) { $0.workspace.tab = .analysis }
        analysis.size = NSSize(width: 1040, height: 960)
        return [general, menuBar, analysis]
    }
}
