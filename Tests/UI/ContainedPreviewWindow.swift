import AppKit

/// Defense in depth for bitmap hosts. Modal destinations must also be excluded before mounting.
final class ContainedPreviewWindow: NSWindow {
    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    override func orderFront(_: Any?) {}
    override func orderBack(_: Any?) {}
    override func orderFrontRegardless() {}
    override func makeKeyAndOrderFront(_: Any?) {}
    override func makeKey() {}
    override func makeMain() {}
    override func order(_: NSWindow.OrderingMode, relativeTo _: Int) {}
    override func beginSheet(_: NSWindow, completionHandler _: ((NSApplication.ModalResponse) -> Void)? = nil) {}
}
