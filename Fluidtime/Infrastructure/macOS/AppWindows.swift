import AppKit
import ComposableArchitecture
import SwiftUI

@MainActor
final class AppWindows: NSObject, NSWindowDelegate {
    static let shared = AppWindows()
    private var store: StoreOf<AppFeature>?
    private var mainWindow: NSWindow?
    private let editor = EntryEditorPopover()

    func configure(store: StoreOf<AppFeature>) {
        self.store = store
        editor.configure(store: store)
    }

    func showMain() {
        guard let store else { return }
        if mainWindow == nil {
            let window = makeWindow(title: String(localized: .fluidtime), size: NSSize(width: 1040, height: 760))
            // Keep native toolbar backgrounds and content in the same window coordinate space.
            window.styleMask.formUnion([.resizable, .fullSizeContentView])
            let hosting = NSHostingController(rootView: MainWindowView(store: store))
            // Let the explicit window limit govern resizing rather than a toolbar control's ideal width.
            hosting.sizingOptions = []
            window.contentViewController = hosting
            window.contentMinSize = NSSize(width: 320, height: 320)
            window.setFrameAutosaveName("Fluidtime.MainWindow")
            mainWindow = window
        }
        show(mainWindow)
        store.send(.interface(.mainWindowOpenChanged(true)))
    }

    func showEditor(anchor: String?) {
        editor.show(anchor: anchor)
    }

    func closeEditor() {
        editor.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        editor.canCloseHost(sender)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === mainWindow {
            store?.send(.interface(.mainWindowOpenChanged(false)))
        }
    }

    private func makeWindow(title: String, size: NSSize) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.delegate = self
        window.center()
        return window
    }

    private func show(_ window: NSWindow?) {
        NSApplication.shared.setActivationPolicy(.regular)
        if window?.isMiniaturized == true {
            window?.deminiaturize(nil)
        }
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
