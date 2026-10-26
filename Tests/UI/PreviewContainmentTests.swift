import AppKit
@testable import FluidtimeCore
import Testing

@MainActor
struct PreviewContainmentTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLUIDTIME_CAPTURE_PREVIEWS"] == "1"))
    func `offscreen capture excludes real confirmation destinations before mounting`() throws {
        let before = Set(NSApplication.shared.windows.map(ObjectIdentifier.init))
        let active = NSWorkspace.shared.frontmostApplication?.processIdentifier
        var state = AppFeature.State()
        state.destination = .disconnect(AppFeature.disconnectConfirmation())
        let preview = ReviewPreviewCase("excluded-confirmation", .settings(0), state: state)
        try ReviewPreviewCapture().captureOffscreen(preview)
        #expect(Set(NSApplication.shared.windows.map(ObjectIdentifier.init)) == before)
        #expect(NSWorkspace.shared.frontmostApplication?.processIdentifier == active)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLUIDTIME_CAPTURE_PREVIEWS"] == "1"))
    func `contained host refuses ordering focus and sheet presentation`() {
        let active = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let host = ContainedPreviewWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        let sheet = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
        host.isReleasedWhenClosed = false
        sheet.isReleasedWhenClosed = false
        defer { sheet.close(); host.close() }
        host.orderFront(nil)
        host.orderBack(nil)
        host.orderFrontRegardless()
        host.order(.above, relativeTo: 0)
        host.makeKeyAndOrderFront(nil)
        host.makeKey()
        host.makeMain()
        host.beginSheet(sheet)
        #expect(!host.isVisible && !host.isKeyWindow && !host.isMainWindow)
        #expect(!sheet.isVisible && host.sheets.isEmpty)
        #expect(NSWorkspace.shared.frontmostApplication?.processIdentifier == active)
    }
}
