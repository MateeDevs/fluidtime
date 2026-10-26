import AppKit
import ComposableArchitecture
@testable import FluidtimeCore

extension ReviewPreviewFixtures {
    func overviewCases() -> [ReviewPreviewCase] {
        var cases = [
            preview("main-overview", .main),
            preview("main-overview-charts", .main) { $0.workspace.tab = .analysis },
            preview("main-overview-daily", .main) { $0.workspace.tab = .daily },
            ReviewPreviewCase("main-welcome", .main, state: AppFeature.State()),
            preview("main-overview-empty", .main) { $0.data.active = nil; $0.data.entries = [] },
            preview("main-overview-unsynced", .main) { $0.data.lastSynced = nil },
            preview("main-overview-updating", .main) { $0.workID = UUID(0); $0.showsProgress = true },
            preview("main-overview-error", .main) {
                $0.error = "Couldn't refresh your entries. Check your connection and try again."
            },
            preview("main-overview-reminder", .main) { $0.reminder = .idle },
            preview("main-overview-custom", .main) { $0.workspace.analysisPeriod = .custom },
            preview("main-overview-targets-off", .main) {
                $0.preferences.workspace.dailyGoalHours = 0; $0.preferences.workspace.weeklyGoalHours = 0
            },
            preview("main-overview-idle", .main) { $0.data.active = nil; $0.data.entries.removeFirst() }
        ]
        var minimum = preview("main-overview-minimum", .main)
        minimum.size = NSSize(width: 820, height: 620)
        cases.append(minimum)
        var dailyNarrow = preview("main-overview-daily-narrow", .main) {
            $0.workspace.tab = .daily
        }
        dailyNarrow.size = NSSize(width: 420, height: 760)
        cases.append(dailyNarrow)
        var middle = preview("main-overview-middle", .main)
        middle.scroll = 0.5
        cases.append(middle)
        var bottom = preview("main-overview-bottom", .main)
        bottom.scroll = 1
        cases.append(bottom)
        var minimumBottom = preview("main-overview-minimum-bottom", .main)
        minimumBottom.size = minimum.size
        minimumBottom.scroll = 1
        cases.append(minimumBottom)
        var dark = preview("main-overview-dark", .main)
        dark.dark = true
        cases.append(dark)
        return cases
    }

    func historyCases() -> [ReviewPreviewCase] {
        var cases = [
            preview("main-history", .main),
            preview("main-history-custom", .main) { $0.workspace.history.period = .custom },
            preview("main-history-no-results", .main) { $0.workspace.history.search = "no matching task" },
            preview("main-history-empty", .main) { $0.data.active = nil; $0.data.entries = [] },
            preview("main-history-updating", .main) { $0.workID = UUID(0); $0.showsProgress = true },
            preview("main-history-export-error", .main) { $0.workspace.exportError = String(localized: .exportFailed) }
        ].map { item in var item = item; item.state.workspace.tab = .history; return item }
        var bottom = preview("main-history-bottom", .main) { $0.workspace.tab = .history }
        bottom.scroll = 1
        cases.append(bottom)
        var minimum = preview("main-history-minimum", .main) { $0.workspace.tab = .history }
        minimum.size = NSSize(width: 820, height: 620)
        var customMinimum = preview("main-history-custom-minimum", .main) {
            $0.workspace.tab = .history; $0.workspace.history.period = .custom
        }
        customMinimum.size = minimum.size
        var dark = preview("main-history-dark", .main) { $0.workspace.tab = .history }
        dark.dark = true
        return cases + [minimum, customMinimum, dark]
    }

    func earningsCases() -> [ReviewPreviewCase] {
        let cases = [
            preview("main-earnings-locked", .main),
            preview("main-earnings-verifying", .main) {
                $0.earnings.pendingSurface = .preview; $0.earnings.operation = UUID(0); $0.earnings.showsProgress = true
            },
            preview("main-earnings-auth-error", .main) { $0.earnings.error = String(localized: .earningsTouchIdFailed)
            },
            preview("main-earnings-unavailable", .main) {
                $0.earnings.error = String(localized: .earningsTouchIdUnavailable)
            },
            preview("main-earnings-unlocked", .main) { unlocked(&$0, surface: .preview) },
            preview("main-earnings-zero-rate", .main) {
                unlocked(&$0, surface: .preview); $0.earnings.settings?.hourlyRate = 0
            },
            preview("main-earnings-billable-only", .main) {
                unlocked(&$0, surface: .preview); $0.workspace.billableOnly = true
            },
            preview("main-earnings-custom", .main) {
                unlocked(&$0, surface: .preview); $0.workspace.analysisPeriod = .custom
            },
            preview("main-earnings-unsynced", .main) { unlocked(&$0, surface: .preview); $0.data.lastSynced = nil }
        ].map { item in var item = item; item.state.workspace.tab = .overview; return item }
        var minimum = preview("main-earnings-minimum", .main) {
            $0.workspace.tab = .overview; unlocked(&$0, surface: .preview)
        }
        minimum.size = NSSize(width: 820, height: 620)
        var dark = preview("main-earnings-dark", .main) {
            $0.workspace.tab = .overview; unlocked(&$0, surface: .preview)
        }
        dark.dark = true
        return cases + [minimum, dark]
    }
}
