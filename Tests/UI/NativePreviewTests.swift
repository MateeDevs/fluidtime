import AppKit
import ComposableArchitecture
@testable import FluidtimeCore
import SwiftUI
import Testing

/// Opt-in visual check. Uses only fictional state and never starts the app's effects.
@MainActor
struct NativePreviewTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLUIDTIME_CAPTURE_PREVIEWS"] == "1"))
    func `capture native views`() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        var state = try makePreviewState()
        try capture(MenuBarView(store: makeStore(state)), name: "running", size: NSSize(width: 380, height: 620))
        state.data.active = nil
        state.data.entries.removeFirst()
        try capture(MenuBarView(store: makeStore(state)), name: "idle", size: NSSize(width: 380, height: 620))
        try capture(SettingsView(store: makeStore(state)), name: "settings", size: NSSize(width: 540, height: 460))
        try capture(
            TrackingSettingsView(store: makeStore(state)), name: "tracking", size: NSSize(width: 540, height: 460)
        )
        try capture(
            MenuBarSettingsView(store: makeStore(state)), name: "menu-bar", size: NSSize(width: 540, height: 460)
        )
        let editor = try EntryEditorFeature.State(
            draft: EntryDraft(entry: state.data.entries[0]), entry: state.data.entries[0],
            connection: #require(state.connection), membership: state.data.memberships[0],
            projects: state.data.projects
        )
        try capture(
            EntryEditorView(store: Store(initialState: editor) { EntryEditorFeature() }),
            name: "editor", size: NSSize(width: 460, height: 440)
        )
        try capture(
            MenuBarView(store: makeStore(AppFeature.State())), name: "welcome", size: NSSize(width: 380, height: 290)
        )
        let iconData = try #require(MenuBarIcon.active.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: iconData))
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: URL(fileURLWithPath: "/private/tmp/fluidtime-tca-active-icon.png"))
    }

    private func makePreviewState() throws -> AppFeature.State {
        var state = AppFeature.State()
        state.connection = try Connection(instance: "https://example.invalid", token: "preview")
        state.data.user = SolidtimeUser(id: "me", name: "Alex", timezone: "Europe/Prague", weekStart: "monday")
        state.data.memberships = [Membership(id: "member", organization: .init(id: "org", name: "Design studio"))]
        state.data.selectedMembershipId = "member"
        state.data.projects = [
            Project(id: "project", name: "Website redesign", color: "#3344ff", isArchived: false, isBillable: true)
        ]
        let now = Date()
        let titles = [
            "Design review", "Navigation and onboarding", "Weekly planning",
            "A longer description that wraps across more than one line in the menu bar", "Prototype updates"
        ]
        state.data.entries = titles.enumerated().map { index, title in
            TimeEntry(
                id: "entry-\(index)", start: now.addingTimeInterval(Double(-index * 7200 - 2700)),
                end: index == 0 ? nil : now.addingTimeInterval(Double(-index * 7200)), description: title,
                projectId: "project", taskId: nil, organizationId: "org", userId: "me", billable: true, tags: []
            )
        }
        state.data.active = state.data.entries[0]
        state.data.lastSynced = now
        return state
    }

    private func makeStore(_ state: AppFeature.State) -> StoreOf<AppFeature> {
        Store(initialState: state) {
            AppFeature()
        } withDependencies: {
            $0.solidtime = .testValue
            $0.credentials = .testValue
            $0.preferences = .testValue
            $0.system = .testValue
            $0.system.setDockIconVisible = { _ in }
            $0.loginItem = .previewValue
        }
    }

    private func capture(_ view: some View, name: String, size: NSSize) throws {
        let hosting = NSHostingView(rootView: view)
        let showsWindow = ProcessInfo.processInfo.environment["FLUIDTIME_VISIBLE_PREVIEWS"] == "1"
        let windowType: NSWindow.Type = showsWindow ? NSWindow.self : ContainedPreviewWindow.self
        let window = windowType.init(
            contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.contentView = hosting
        if showsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        hosting.frame = NSRect(origin: .zero, size: size)
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))
        hosting.layoutSubtreeIfNeeded()
        let path = "/private/tmp/fluidtime-tca-\(name).png"
        if !showsWindow {
            try #require(!window.isVisible)
            let bitmap = try #require(hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds))
            hosting.cacheDisplay(in: hosting.bounds, to: bitmap)
            let data = try #require(bitmap.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: path))
            return
        }
        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        capture.arguments = ["-x", "-l", String(window.windowNumber), path]
        try capture.run()
        capture.waitUntilExit()
        #expect(capture.terminationStatus == 0)
        window.orderOut(nil)
    }
}
