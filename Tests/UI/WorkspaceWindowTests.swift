import AppKit
import ComposableArchitecture
@testable import FluidtimeCore
import SwiftUI
import Testing

/// Opt-in native interaction diagnostic. All session data is fictional and service actions are ignored.
@MainActor
struct WorkspaceWindowTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLUIDTIME_WORKSPACE_DIAGNOSTIC"] == "1"
              && ProcessInfo.processInfo.environment["FLUIDTIME_VISIBLE_PREVIEWS"] == "1"),
    arguments: WorkspaceFeature.Tab.allCases)
    func `view transitions preserve the timer header layout`(_ tab: WorkspaceFeature.Tab) throws {
        var state = try ReviewPreviewFixtures().state
        state.workspace.tab = tab
        let store = Store(initialState: state) { ReviewPreviewReducer() }
        let windows = AppWindows()
        windows.configure(store: store)
        windows.showMain()
        let window = try #require(NSApplication.shared.windows.first { $0.isVisible })
        defer { window.close() }
        if ProcessInfo.processInfo.environment["FLUIDTIME_WORKSPACE_LEGACY_HOST"] == "1" {
            window.styleMask.remove(.fullSizeContentView)
        }
        window.setContentSize(NSSize(width: 1040, height: 760))
        settle()
        try capture(window, name: "\(tab.rawValue)-initial")
        for destination in WorkspaceFeature.Tab.allCases {
            store.send(.workspace(.view(.binding(.set(\.tab, destination)))))
            settle()
            try capture(window, name: "\(tab.rawValue)-to-\(destination.rawValue)")
        }
    }

    private func capture(_ window: NSWindow, name: String) throws {
        let path = ProcessInfo.processInfo.environment["FLUIDTIME_WORKSPACE_DIAGNOSTIC_DIRECTORY"]
            ?? "/private/tmp/fluidtime-workspace-diagnostic"
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        print("WORKSPACE \(name) style=\(window.styleMask.rawValue) toolbar=\(window.toolbarStyle.rawValue)")
        print("frame=\(window.frame) content=\(window.contentView?.frame ?? .zero) layout=\(window.contentLayoutRect)")
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = [
            "-x",
            "-o",
            "-l",
            String(window.windowNumber),
            directory.appendingPathComponent(name + ".png").path
        ]
        try task.run()
        task.waitUntilExit()
        try #require(task.terminationStatus == 0)
        // Keep native implementation-detail inspection confined to this opt-in diagnostic.
        let backgrounds = descendants(window.contentView).filter {
            NSStringFromClass(Swift.type(of: $0)) == "NSTitlebarBackgroundView" && $0.bounds.width > 0
        }
        for background in backgrounds {
            let rect = background.convert(background.bounds, to: nil)
            print("TITLEBAR \(name) rect=\(rect) contentTop=\(window.contentLayoutRect.maxY)")
            #expect(rect.minY >= window.contentLayoutRect.maxY - 1,
                    "Native titlebar background must not cover the timer header below the toolbar")
        }
    }

    private func descendants(_ view: NSView?) -> [NSView] {
        guard let view else { return [] }
        return [view] + view.subviews.flatMap(descendants)
    }

    private func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.8))
    }
}
