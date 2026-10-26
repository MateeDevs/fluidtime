import AppKit
import ComposableArchitecture
@testable import FluidtimeCore
import SwiftUI
import Testing

extension ReviewPreviewCapture {
    /// Uses the production window factory while the store continues to ignore all service actions.
    func captureNativeWindow(_ preview: ReviewPreviewCase) throws {
        try #require(showsWindows)
        var state = preview.state
        if let editor = preview.editor {
            state.destination = .editor(editor)
        }
        let store = Store(initialState: state) { ReviewPreviewReducer() }
        let windows = AppWindows()
        windows.configure(store: store)
        var existing = Set(NSApplication.shared.windows.map(ObjectIdentifier.init))
        var editorHost: NSWindow?
        defer {
            windows.closeEditor()
            editorHost?.close()
        }
        switch preview.screen {
        case .main:
            windows.showMain()
        case .editor:
            windows.showMain()
            settle()
            editorHost = NSApplication.shared.keyWindow
            existing = Set(NSApplication.shared.windows.map(ObjectIdentifier.init))
            windows.showEditor(anchor: nil)
        default:
            Issue.record("Native window capture supports the main window and editor only.")
            return
        }
        settle()
        let window = try #require(NSApplication.shared.windows.first {
            $0.isVisible && !existing.contains(ObjectIdentifier($0))
        })
        defer { window.close() }
        window.level = .floating
        let usesIntrinsicSize = ProcessInfo.processInfo.environment["FLUIDTIME_PREVIEW_NATIVE_SHELL"] == "1"
        if case .main = preview.screen, !usesIntrinsicSize {
            if preview.rightToLeft {
                window.contentViewController = NSHostingController(rootView: preview.view)
            }
            window.setContentSize(preview.size)
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        settle()
        scroll(preview.scroll, window: window)
        if ProcessInfo.processInfo.environment["FLUIDTIME_PREVIEW_FLASH_SCROLLERS"] == "1" {
            flashScrollers(in: window.contentView)
        }
        try save(window, preview: preview)
    }

    private func flashScrollers(in view: NSView?) {
        guard let view else { return }
        if let scroll = view as? NSScrollView {
            scroll.flashScrollers()
        }
        for child in view.subviews {
            flashScrollers(in: child)
        }
    }
}
