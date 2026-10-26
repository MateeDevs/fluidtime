import Foundation

struct MenuBarPresentation: Equatable {
    let text: String?
    let showsActiveIndicator: Bool
    let activeProjectColor: String?
    let accessibilityLabel: String

    init(data: SessionData, preferences: AppPreferences, now: Date) {
        switch preferences.menuBarDisplay {
        case .elapsed:
            text = data.active.map {
                TrackedTime.clock($0.elapsed(at: now), showsSeconds: preferences.menuBarShowsSeconds)
            }
        case .today:
            text = data.lastSynced == nil ? nil
                : TrackedTime.clock(data.totals(at: now).today, showsSeconds: preferences.menuBarShowsSeconds)
        case .week:
            text = data.lastSynced == nil ? nil
                : TrackedTime.clock(data.totals(at: now).week, showsSeconds: preferences.menuBarShowsSeconds)
        case .indicator, .clock:
            text = nil
        }
        showsActiveIndicator = data.active != nil
        activeProjectColor = Self.projectColor(data, preferences: preferences)
        if data.lastSynced == nil, data.active == nil {
            accessibilityLabel = String(localized: .fluidtime)
        } else if preferences.menuBarDisplay == .today, let text {
            accessibilityLabel = data.active == nil ? String(localized: .fluidtimeTodaysTotal(text))
                : String(localized: .fluidtimeTimerRunningTodaysTotal(text))
        } else if preferences.menuBarDisplay == .week, let text {
            accessibilityLabel = data.active == nil ? String(localized: .fluidtimeThisWeeksTotal(text))
                : String(localized: .fluidtimeTimerRunningThisWeeksTotal(text))
        } else if let text {
            accessibilityLabel = String(localized: .fluidtimeTimerRunning(text))
        } else {
            accessibilityLabel = data.active == nil
                ? String(localized: .fluidtimeNoTimerRunning) : String(localized: .fluidtimeTimerRunning)
        }
    }

    private static func projectColor(_ data: SessionData, preferences: AppPreferences) -> String? {
        guard preferences.menuBarUsesProjectColor, let active = data.active,
              active.organizationId == data.membership?.organization.id else { return nil }
        return data.projects.first { $0.id == active.projectId }?.color
    }
}
