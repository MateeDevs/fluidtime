import AppKit
import ComposableArchitecture
import SwiftUI

struct SettingsWindowObserver: NSViewRepresentable {
    let store: StoreOf<AppFeature>

    private var onChange: @MainActor (Bool) -> Void {
        { [store] isOpen in store.send(.interface(.settingsWindowOpenChanged(isOpen))) }
    }

    func makeNSView(context _: Context) -> WindowView {
        let view = WindowView()
        view.onChange = onChange
        return view
    }

    func updateNSView(_ view: WindowView, context _: Context) {
        view.onChange = onChange
    }

    static func dismantleNSView(_ view: WindowView, coordinator _: ()) {
        view.stopObserving()
    }

    final class WindowView: NSView {
        var onChange: (@MainActor (Bool) -> Void)?
        private weak var observedWindow: NSWindow?
        private var isOpen = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window !== observedWindow else { return }
            stopObserving()
            guard let window else { return }
            observedWindow = window
            let notifications = NotificationCenter.default
            notifications.addObserver(
                self, selector: #selector(windowOpened), name: NSWindow.didBecomeKeyNotification, object: window
            )
            notifications.addObserver(
                self, selector: #selector(windowClosed), name: NSWindow.willCloseNotification, object: window
            )
            setOpen(window.isVisible)
        }

        func stopObserving() {
            NotificationCenter.default.removeObserver(
                self, name: NSWindow.didBecomeKeyNotification, object: observedWindow
            )
            NotificationCenter.default.removeObserver(
                self, name: NSWindow.willCloseNotification, object: observedWindow
            )
            observedWindow = nil
            setOpen(false)
        }

        @objc private func windowOpened() {
            setOpen(true)
        }

        @objc private func windowClosed() {
            setOpen(false)
        }

        private func setOpen(_ value: Bool) {
            guard isOpen != value else { return }
            isOpen = value
            let onChange = onChange
            DispatchQueue.main.async { onChange?(value) }
        }
    }
}
