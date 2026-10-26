import AppKit
@testable import FluidtimeCore
import SwiftUI
import Testing

extension ReviewPreviewCapture {
    func captureOffscreen(_ preview: ReviewPreviewCase) throws {
        // Do not mount actual sheets or confirmations in a bitmap host. Their native
        // presentation can create independent windows beyond the host containment.
        guard preview.state.destination == nil else {
            print("Skipped modal preview: \(preview.name). Modal interaction needs an isolated desktop.")
            return
        }
        let view = NSHostingView(rootView: preview.view)
        let window = ContainedPreviewWindow(
            contentRect: NSRect(origin: .zero, size: preview.size),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.setContentSize(preview.size)
        view.frame = NSRect(origin: .zero, size: preview.size)
        defer { window.close() }
        settle()
        view.layoutSubtreeIfNeeded()
        scroll(preview.scroll, window: window)
        try #require(!window.isVisible)
        try save(window, preview: preview)
    }
}
