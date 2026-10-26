import AppKit
import SwiftUI

/// Identifies the edit control's native position without intercepting its mouse events.
struct EntryEditorAnchorView: NSViewRepresentable {
    let id: String

    func makeNSView(context _: Context) -> NSView {
        AnchorView()
    }

    func updateNSView(_ view: NSView, context _: Context) {
        view.identifier = NSUserInterfaceItemIdentifier(id)
    }

    private final class AnchorView: NSView {
        override func hitTest(_: NSPoint) -> NSView? {
            nil
        }
    }
}
