import Foundation

enum LaunchAtLoginStatus: Equatable, Sendable {
    case disabled, enabled, requiresApproval, unavailable

    var isRegistered: Bool {
        self == .enabled || self == .requiresApproval
    }
}
