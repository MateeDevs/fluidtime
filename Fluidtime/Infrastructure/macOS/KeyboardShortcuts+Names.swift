import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    #if FLUIDTIME_ALPHA
        static let openFluidtime = Self("openFluidtime")
        static let toggleFluidtimeTimer = Self("toggleFluidtimeTimer")
    #else
        static let openFluidtime = Self(
            "openFluidtime",
            initial: .init(.f, modifiers: [.control, .option, .shift, .command])
        )
        static let toggleFluidtimeTimer = Self(
            "toggleFluidtimeTimer", initial: .init(.t, modifiers: [.control, .option, .shift, .command])
        )
    #endif
}
