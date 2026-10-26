import AppKit
@testable import FluidtimeCore
import Testing

/// Explicitly authorized native history checks use fictional data and ignore service actions.
@MainActor
struct HistoryLayoutTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLUIDTIME_HISTORY_LAYOUT"] == "1"
            && ProcessInfo.processInfo.environment["FLUIDTIME_VISIBLE_PREVIEWS"] == "1"))
    func `history rows align with filters and leave room for the scrollbar`() throws {
        NSApplication.shared.setActivationPolicy(.accessory)
        let fixtures = try ReviewPreviewFixtures()
        let capture = try ReviewPreviewCapture()
        var preview = fixtures.preview("history-wide", .main) { $0.workspace.tab = .history }
        try capture.capture(preview)
        preview = fixtures.preview("history-narrow", .main) {
            $0.workspace.tab = .history
        }
        preview.size = NSSize(width: 420, height: 760)
        try capture.capture(preview)
        try capture.finish()
    }
}
