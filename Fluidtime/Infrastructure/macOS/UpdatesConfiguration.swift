import Foundation

/// Enable Sparkle only in app bundles that explicitly configure updates.
enum UpdatesConfiguration {
    static var isEnabled: Bool {
        Bundle.main.object(forInfoDictionaryKey: "FluidtimeUpdatesEnabled") as? Bool ?? false
    }
}
