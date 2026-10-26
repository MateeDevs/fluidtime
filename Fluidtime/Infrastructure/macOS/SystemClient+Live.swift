import AppKit
import ComposableArchitecture
import CoreGraphics

extension SystemClient: DependencyKey {
    static let liveValue = Self(
        openURL: { NSWorkspace.shared.open($0) },
        quit: { NSApplication.shared.terminate(nil) },
        setDockIconVisible: { isVisible in
            NSApplication.shared.setActivationPolicy(isVisible ? .regular : .accessory)
            if isVisible {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        },
        openMainWindow: { AppWindows.shared.showMain() },
        openEntryEditor: { AppWindows.shared.showEditor(anchor: $0) },
        closeEntryEditor: { AppWindows.shared.closeEditor() },
        showTimerFeedback: { TimerFeedbackPanel.shared.show($0) },
        idleSeconds: {
            // kCGAnyInputEventType is not imported into Swift; its C value has every bit set.
            guard let event = CGEventType(rawValue: UInt32.max) else { return 0 }
            return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: event)
        },
        exportCSV: { try await CSVExport.save($0) }
    )
}
