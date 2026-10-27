import AppKit
import ComposableArchitecture
@testable import FluidtimeCore
import SwiftUI
import Testing

/// Opt-in offscreen checks use fictional state and never execute service effects.
@MainActor
struct WorkspaceViewportTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLUIDTIME_VIEWPORT_CHECK"] == "1"))
    func `daily list stays inside the window and reaches both ends`() throws {
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        let fixtures = try ReviewPreviewFixtures()
        var state = fixtures.preview("viewport", .main).state
        state.workspace.tab = .daily
        let store = Store(initialState: state) { ReviewPreviewReducer() }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 560),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let hosting = NSHostingController(rootView: MainWindowView(store: store))
        hosting.sizingOptions = []
        window.contentViewController = hosting
        defer { window.close() }
        let capture = try ReviewPreviewCapture()
        let sizes = [NSSize(width: 640, height: 560), NSSize(width: 760, height: 620),
                     NSSize(width: 1040, height: 760)]
        for sidebar in [true, false] {
            store.send(.view(.binding(.set(\.workspace.columnVisibility, sidebar ? .all : .detailOnly))))
            for size in sizes {
                window.setContentSize(size)
                capture.settle()
                try checkViewport(hosting.view, window: window, capture: capture,
                                  state: state, name: "daily-\(Int(size.width))-\(sidebar)")
            }
        }
        try capture.finish()
    }

    private func checkViewport(
        _ root: NSView, window: NSWindow, capture: ReviewPreviewCapture,
        state: AppFeature.State, name: String
    ) throws {
        let views = descendants(root)
        let split = try #require(views.compactMap { $0 as? NSSplitView }.first)
        #expect(root.bounds.insetBy(dx: -1, dy: -1).contains(split.convert(split.bounds, to: root)))
        let tables = views.compactMap { $0 as? NSTableView }
        let daily = try #require(tables.max { $0.numberOfRows < $1.numberOfRows })
        #expect(daily.numberOfRows > 4)
        #expect(daily.bounds.width >= 430)
        if root.bounds.width < 760 {
            #expect(daily.bounds.width >= root.bounds.width - 1)
        }
        let scroll = try #require(daily.enclosingScrollView)
        let viewport = scroll.convert(scroll.bounds, to: root)
        #expect(root.bounds.insetBy(dx: -1, dy: -1).contains(viewport))
        for bottom in [false, true] {
            let row = bottom ? daily.numberOfRows - 1 : 0
            daily.scrollRowToVisible(row)
            capture.settle()
            let rect = daily.rect(ofRow: row)
            let edge = bottom ? rect.maxY - 1 : rect.minY
            daily.scrollToVisible(NSRect(x: 0, y: edge, width: 1, height: 1))
            capture.settle()
            let visible = daily.visibleRect
            let finalRect = daily.rect(ofRow: row)
            #expect(bottom ? finalRect.maxY <= visible.maxY + 1 : finalRect.minY >= visible.minY - 1)
            let preview = ReviewPreviewCase("\(name)-\(bottom ? "bottom" : "top")", .main, state: state)
            try capture.save(window, preview: preview)
        }
        #expect(!window.isVisible && !window.isKeyWindow && !window.isMainWindow)
    }

    private func descendants(_ view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap { descendants($0) }
    }
}
