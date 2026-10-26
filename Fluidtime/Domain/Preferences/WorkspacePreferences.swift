import Foundation

struct WorkspacePreferences: Codable, Equatable, Sendable {
    var dailyGoalHours = 8.0
    var weeklyGoalHours = 40.0
    var earningsEnabled = false
    var timerFeedback = true
    var idleReminderMinutes = 0
    var longTimerReminderHours = 0
    var presets: [TimerPreset] = []
    var lunchWindow = LunchWindow()
    var navigation: [String: WorkspaceNavigation] = [:]
}

struct TimerPreset: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let scope: String
    var description: String
    var projectId: String

    var title: String {
        description.isEmpty ? String(localized: .noDescription) : description
    }
}

extension WorkspacePreferences {
    private enum CodingKeys: String, CodingKey {
        case dailyGoalHours, weeklyGoalHours, timerFeedback, earningsEnabled
        case idleReminderMinutes, longTimerReminderHours, presets, lunchWindow, navigation
    }

    init(from decoder: any Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dailyGoalHours = try values.decodeIfPresent(Double.self, forKey: .dailyGoalHours) ?? dailyGoalHours
        weeklyGoalHours = try values.decodeIfPresent(Double.self, forKey: .weeklyGoalHours) ?? weeklyGoalHours
        earningsEnabled = try values.decodeIfPresent(Bool.self, forKey: .earningsEnabled) ?? false
        timerFeedback = try values.decodeIfPresent(Bool.self, forKey: .timerFeedback) ?? timerFeedback
        idleReminderMinutes = try values.decodeIfPresent(Int.self, forKey: .idleReminderMinutes) ?? idleReminderMinutes
        longTimerReminderHours = try values.decodeIfPresent(Int.self, forKey: .longTimerReminderHours)
            ?? longTimerReminderHours
        navigation = try values.decodeIfPresent([String: WorkspaceNavigation].self, forKey: .navigation) ?? [:]
        presets = try values.decodeIfPresent([TimerPreset].self, forKey: .presets) ?? presets
        lunchWindow = try values.decodeIfPresent(LunchWindow.self, forKey: .lunchWindow)?.normalized ?? lunchWindow
    }
}

struct WorkspaceNavigation: Codable, Equatable, Sendable {
    var destination: String
}
