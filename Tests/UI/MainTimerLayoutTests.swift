import AppKit
import ComposableArchitecture
@testable import FluidtimeCore
import SwiftUI
import Testing

@MainActor
struct MainTimerLayoutTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["FLUIDTIME_VIEWPORT_CHECK"] == "1"))
    func `collapsed main timer stays on one line and releases vertical space`() throws {
        let fixtures = try ReviewPreviewFixtures()
        for running in [true, false] {
            var state = fixtures.preview("timer", .main).state
            if !running {
                state.data.active = nil
            }
            let store = Store(initialState: state) { ReviewPreviewReducer() }
            let size = LockIsolated(CGSize.zero)
            let view = VStack(spacing: 0) {
                MainTimerControls(store: store)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { value in
                        size.setValue(value)
                    }
                Spacer(minLength: 0)
            }
            let host = NSHostingView(rootView: view)
            host.sizingOptions = []
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 430, height: 560),
                                  styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = host
            try checkSizes(window: window, store: store, size: size)
            window.close()
        }
    }

    private func checkSizes(window: NSWindow, store: StoreOf<AppFeature>, size: LockIsolated<CGSize>) throws {
        let capture = try ReviewPreviewCapture()
        for width in [430, 640, 830] {
            window.setContentSize(NSSize(width: width, height: 560))
            store.send(.workspace(.view(.binding(.set(\.isTimerCollapsed, false)))))
            capture.settle()
            let expanded = size.value
            store.send(.workspace(.view(.binding(.set(\.isTimerCollapsed, true)))))
            capture.settle()
            #expect(size.value.height <= 48)
            #expect(size.value.height < expanded.height)
            #expect(abs(size.value.width - CGFloat(width)) < 1)
            #expect(!window.isVisible && !window.isKeyWindow)
        }
    }
}
