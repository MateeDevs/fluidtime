import AppKit
@testable import FluidtimeCore
import SwiftUI
import Testing

@MainActor
final class ReviewPreviewCapture {
    let directory: URL
    private var records: [[String: String]] = []
    var showsWindows: Bool {
        ProcessInfo.processInfo.environment["FLUIDTIME_VISIBLE_PREVIEWS"] == "1"
    }

    private var usesBitmap: Bool {
        !showsWindows || ProcessInfo.processInfo.environment["FLUIDTIME_PREVIEW_CACHE"] == "1"
    }

    init() throws {
        let path = ProcessInfo.processInfo.environment["FLUIDTIME_PREVIEW_DIRECTORY"]
            ?? "/private/tmp/fluidtime-ui-review-2026-10-22"
        directory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func capture(_ preview: ReviewPreviewCase) throws {
        let appearance: NSAppearance.Name = preview.increasedContrast
            ? (preview.dark ? .accessibilityHighContrastDarkAqua : .accessibilityHighContrastAqua)
            : (preview.dark ? .darkAqua : .aqua)
        NSApplication.shared.appearance = NSAppearance(named: appearance)
        guard showsWindows else {
            try captureOffscreen(preview)
            return
        }
        if case .main = preview.screen {
            try captureNativeWindow(preview)
            return
        }
        if case .editor = preview.screen {
            try captureNativeWindow(preview)
            return
        }
        if case let .feedback(feedback) = preview.screen {
            try captureFeedback(feedback, preview: preview)
            return
        }
        let chrome: NSWindow.StyleMask = switch preview.screen {
        case .main: [.titled, .closable, .miniaturizable, .resizable]
        case .editor: [.titled, .closable, .miniaturizable]
        case .settings: [.borderless]
        default: [.borderless]
        }
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: preview.size), styleMask: chrome,
                              backing: .buffered, defer: false)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.title = "Fluidtime preview"
        if case .settings = preview.screen {
            window.contentView = NSHostingView(rootView: preview.view)
        } else {
            let hosting = NSHostingController(rootView: preview.view)
            window.contentViewController = hosting
        }
        window.setContentSize(preview.size)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        defer { window.close() }
        settle()
        window.setContentSize(preview.size)
        window.center()
        window.makeKeyAndOrderFront(nil)
        settle()
        scroll(preview.scroll, window: window)
        try save(window, preview: preview)
    }

    func finish() throws {
        let data = try JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: directory.appendingPathComponent("manifest.json"))
    }

    private func captureFeedback(_ feedback: TimerFeedback, preview: ReviewPreviewCase) throws {
        TimerFeedbackPanel.shared.show(feedback)
        settle()
        let window = try #require(NSApplication.shared.windows.first {
            $0 is NSPanel && $0.isVisible && $0.frame.width == 240
        })
        defer { window.orderOut(nil) }
        try save(window, preview: preview)
    }

    func save(_ window: NSWindow, preview: ReviewPreviewCase) throws {
        let path = directory.appendingPathComponent(preview.name + ".png").path
        let process = Process()
        print(
            "Capturing \(preview.name), visible=\(window.isVisible), key=\(window.isKeyWindow), frame=\(window.frame)"
        )
        if usesBitmap {
            let view = try #require(window.contentView)
            let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: bitmap)
            let data = try #require(bitmap.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: path))
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-x", "-o", "-l", String(window.windowNumber), path]
            try process.run()
            process.waitUntilExit()
            try #require(process.terminationStatus == 0)
        }
        let image = try #require(NSBitmapImageRep(data: Data(contentsOf: URL(fileURLWithPath: path))))
        records.append([
            "name": preview.name, "appearance": preview.dark ? "dark" : "light",
            "requested": "\(preview.size.width) × \(preview.size.height)",
            "content": NSStringFromRect(window.contentRect(forFrameRect: window.frame)),
            "pixels": "\(image.pixelsWide) × \(image.pixelsHigh)",
            "scroll": preview.scroll.formatted(), "screen": String(describing: preview.screen),
            "captureMethod": usesBitmap ? "native-view-bitmap" : "window-server",
            "presentation": showsWindows ? "visible" : "offscreen",
            "background": preview.dark ? "#1e1e1e" : "#ffffff",
            "keyWindow": window.isKeyWindow.description, "applicationActive": NSApplication.shared.isActive.description
        ])
        print("Captured \(preview.name): \(image.pixelsWide) × \(image.pixelsHigh)")
    }

    func scroll(_ fraction: CGFloat, window: NSWindow) {
        guard fraction > 0 else { return }
        let candidates = descendants(window.contentView).compactMap { $0 as? NSScrollView }.filter {
            $0.bounds.height > 150 && ($0.documentView?.bounds.height ?? 0) > $0.contentView.bounds.height
        }
        let selected = candidates.max { ($0.documentView?.bounds.height ?? 0) < ($1.documentView?.bounds.height ?? 0) }
        guard let scroll = selected, let document = scroll.documentView else { return }
        let distance = max(0, document.bounds.height - scroll.contentView.bounds.height)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: distance * fraction))
        scroll.reflectScrolledClipView(scroll.contentView)
        settle()
    }

    private func descendants(_ view: NSView?) -> [NSView] {
        guard let view else { return [] }
        return [view] + view.subviews.flatMap { descendants($0) }
    }

    func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))
    }
}
