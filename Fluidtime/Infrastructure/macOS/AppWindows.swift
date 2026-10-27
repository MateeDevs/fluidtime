import AppKit
import ComposableArchitecture
import SwiftUI

@MainActor
final class AppWindows: NSObject, NSWindowDelegate {
    static let shared = AppWindows()
    private var store: StoreOf<AppFeature>?
    private var mainWindow: NSWindow?
    private let editor = EntryEditorWindow()

    func configure(store: StoreOf<AppFeature>) {
        self.store = store
        editor.configure(store: store)
    }

    func showMain() {
        guard let store else { return }
        if mainWindow == nil {
            #if FLUIDTIME_ALPHA
                let title = String(localized: .alphaTitle)
            #else
                let title = String(localized: .fluidtime)
            #endif
            let window = makeWindow(title: title, size: NSSize(width: 1040, height: 760))
            // Keep native toolbar backgrounds and content in the same window coordinate space.
            window.styleMask.formUnion([.resizable, .fullSizeContentView])
            let hosting = NSHostingController(rootView: MainWindowView(store: store))
            // Let the explicit window limit govern resizing rather than a toolbar control's ideal width.
            hosting.sizingOptions = []
            window.contentViewController = hosting
            window.contentMinSize = NSSize(width: 640, height: 560)
            window.setFrameAutosaveName("Fluidtime.MainWindow")
            let restoredSize = window.contentRect(forFrameRect: window.frame).size
            window.setContentSize(NSSize(width: max(640, restoredSize.width), height: max(560, restoredSize.height)))
            mainWindow = window
        }
        show(mainWindow)
        store.send(.interface(.mainWindowOpenChanged(true)))
    }

    func showEditor(anchor _: String?) {
        editor.show()
    }

    func closeEditor() {
        editor.close()
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === mainWindow {
            store?.send(.interface(.mainWindowOpenChanged(false)))
        }
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard sender === mainWindow else { return frameSize }
        let minimum = sender.frameRect(forContentRect: NSRect(x: 0, y: 0, width: 640, height: 560)).size
        return NSSize(width: max(minimum.width, frameSize.width), height: max(minimum.height, frameSize.height))
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
