import AppKit
import ComposableArchitecture
@testable import FluidtimeCore
import Testing

@MainActor
struct SettingsWindowObserverTests {
    @Test func `window events track reopening and ignore other windows`() async {
        _ = NSApplication.shared
        let changes = LockIsolated<[Bool]>([])
        let view = SettingsWindowObserver.WindowView()
        view.onChange = { isOpen in changes.withValue { $0.append(isOpen) } }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        let otherWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.contentView = view
        let notifications = NotificationCenter.default
        notifications.post(name: NSWindow.didBecomeKeyNotification, object: otherWindow)
        notifications.post(name: NSWindow.didBecomeKeyNotification, object: window)
        notifications.post(name: NSWindow.didBecomeKeyNotification, object: window)
        notifications.post(name: NSWindow.willCloseNotification, object: window)
        notifications.post(name: NSWindow.didBecomeKeyNotification, object: window)
        await drainCallbacks()
        #expect(changes.value == [true, false, true])

        view.stopObserving()
        notifications.post(name: NSWindow.didBecomeKeyNotification, object: window)
        await drainCallbacks()
        #expect(changes.value == [true, false, true, false])
    }

    private func drainCallbacks() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
