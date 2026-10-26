import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openFluidtime = Self(
        "openFluidtime",
        initial: .init(.f, modifiers: [.control, .option, .shift, .command])
    )
    static let toggleFluidtimeTimer = Self(
        "toggleFluidtimeTimer", initial: .init(.t, modifiers: [.control, .option, .shift, .command])
    )
}
