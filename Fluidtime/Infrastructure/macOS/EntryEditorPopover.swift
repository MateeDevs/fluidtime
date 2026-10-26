import AppKit
import ComposableArchitecture
import SwiftUI

@MainActor
final class EntryEditorPopover: NSObject, NSPopoverDelegate {
    private var store: StoreOf<AppFeature>?
    private var popover: NSPopover?
    private weak var hostWindow: NSWindow?

    func configure(store: StoreOf<AppFeature>) {
        self.store = store
    }

    func show(anchor: String?) {
        guard let store,
              let editor = store.scope(state: \.destination?.editor, action: \.destination.editor) else { return }
        guard let view = positioningView(anchor: anchor) else {
            store.send(.interface(.editorPresentationChanged(false)))
            return
        }
        let calendar = store.user?.calendar ?? .current
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        popover.delegate = self
        let controller = NSHostingController(
            rootView: EntryEditorView(store: editor)
                .environment(\.calendar, calendar)
                .environment(\.timeZone, calendar.timeZone)
        )
        controller.sizingOptions = [.preferredContentSize]
        popover.contentViewController = controller
        self.popover = popover
        hostWindow = view.window
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        store.send(.interface(.editorPresentationChanged(popover.isShown)))
    }

    func close() {
        popover?.close()
    }

    func canCloseHost(_ window: NSWindow) -> Bool {
        window !== hostWindow || store?.destination?.editor?.isSaving != true
    }

    func popoverShouldClose(_: NSPopover) -> Bool {
        store?.destination?.editor?.isSaving != true
    }

    func popoverDidClose(_: Notification) {
        popover = nil
        hostWindow = nil
        store?.send(.interface(.editorPresentationChanged(false)))
    }

    private func positioningView(anchor: String?) -> NSView? {
        if let anchor {
            return NSApp.windows.lazy.compactMap { window in
                window.isVisible ? window.contentView.flatMap { self.findAnchor(anchor, in: $0) } : nil
            }.first
        }
        return NSApp.keyWindow?.contentView
    }

    private func findAnchor(_ id: String, in view: NSView) -> NSView? {
        guard !view.isHiddenOrHasHiddenAncestor else { return nil }
        if view.identifier?.rawValue == id, !view.visibleRect.isEmpty {
            return view
        }
        for child in view.subviews {
            if let result = findAnchor(id, in: child) {
                return result
            }
        }
        return nil
    }
}
