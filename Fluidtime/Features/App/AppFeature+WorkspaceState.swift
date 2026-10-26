import Foundation

extension AppFeature.State {
    var accountScope: String {
        guard let connection, let user, let membership = data.membership else { return "" }
        return [connection.instance.absoluteString, user.id, membership.organization.id].joined(separator: "|")
    }

    var pinnedPresets: [TimerPreset] {
        preferences.workspace.presets.filter { $0.scope == accountScope }
    }

    var showsDockIcon: Bool {
        isSettingsWindowOpen || isMainWindowOpen
    }
}

enum TimerReminder: String, Equatable, Hashable, Sendable {
    case idle, longRunning

    var message: LocalizedStringResource {
        self == .idle ? .reminderIdleBody : .reminderLongBody
    }
}
