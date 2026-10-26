import AppKit
import SwiftUI

@MainActor
final class TimerFeedbackPanel {
    static let shared = TimerFeedbackPanel()
    private var panel: NSPanel?
    private weak var statusItem: NSStatusItem?
    private var dismissal: Task<Void, Never>?

    func anchor(to statusItem: NSStatusItem) {
        self.statusItem = statusItem
        if let panel, panel.isVisible {
            position(panel)
        }
    }

    func show(_ feedback: TimerFeedback) {
        dismissal?.cancel()
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = NSHostingView(rootView: TimerFeedbackView(feedback: feedback))
        position(panel)
        panel.orderFrontRegardless()
        NSAccessibility.post(element: panel, notification: .announcementRequested, userInfo: [
            .announcement: String(localized: .feedbackAnnouncement(String(localized: feedback.title), feedback.detail))
        ])
        dismissal = Task { [weak self] in
            // The menu label can resize after a timer changes; follow its native button for four seconds.
            for _ in 0 ..< 20 {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                self?.position(panel)
            }
            panel.orderOut(nil)
        }
    }

    private func position(_ panel: NSPanel) {
        let button = statusItem?.button
        let window = button?.window
        guard let screen = window?.screen ?? NSScreen.main else { return }
        let anchor = button.flatMap { button in
            window?.convertToScreen(button.convert(button.bounds, to: nil))
        }
        panel.setFrameOrigin(TimerFeedbackPlacement.origin(size: panel.frame.size, anchor: anchor,
                                                           visibleFrame: screen.visibleFrame))
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: TimerFeedbackView.size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
        )
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        return panel
    }
}

struct TimerFeedbackView: View {
    static let size = NSSize(width: 240, height: 56)
    let feedback: TimerFeedback

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(feedback.title).font(.system(size: 13, weight: .semibold))
                Text(verbatim: feedback.detail).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(.regularMaterial, in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch feedback {
        case .started: "play.fill"
        case .stopped: "stop.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .idleReminder, .longRunningReminder: "clock.badge.exclamationmark"
        }
    }

    private var tint: Color {
        switch feedback {
        case .started: .accentColor
        case .stopped: .secondary
        case .failed, .idleReminder, .longRunningReminder: .orange
        }
    }
}
