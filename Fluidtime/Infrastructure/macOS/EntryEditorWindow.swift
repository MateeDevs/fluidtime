import AppKit
import ComposableArchitecture
import SwiftUI

@MainActor
final class EntryEditorWindow: NSObject, NSWindowDelegate {
    private var store: StoreOf<AppFeature>?
    private var window: NSWindow?

    func configure(store: StoreOf<AppFeature>) {
        self.store = store
    }

    func show() {
        guard let store,
              let editor = store.scope(state: \.destination?.editor, action: \.destination.editor) else { return }
        let calendar = store.user?.calendar ?? .current
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
        )
        window.title = String(localized: .editTimeEntry)
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.delegate = self
        window.contentViewController = NSHostingController(
            rootView: EntryEditorView(store: editor)
                .environment(\.calendar, calendar)
                .environment(\.timeZone, calendar.timeZone)
        )
        if !window.setFrameUsingName("Fluidtime.EntryEditor") {
            window.center()
        }
        window.setFrameAutosaveName("Fluidtime.EntryEditor")
        self.window = window
        NSApplication.shared.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        store.send(.interface(.editorPresentationChanged(true)))
    }

    func close() {
        window?.close()
    }

    func windowShouldClose(_: NSWindow) -> Bool {
        store?.destination?.editor?.isSaving != true
    }

    func windowWillClose(_: Notification) {
        window = nil
        store?.send(.interface(.editorPresentationChanged(false)))
    }
}
