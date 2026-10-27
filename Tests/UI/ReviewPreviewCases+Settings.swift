import AppKit
import ComposableArchitecture
@testable import FluidtimeCore

extension ReviewPreviewFixtures {
    func accountCases() -> [ReviewPreviewCase] {
        var cases = [
            preview("settings-account-connected", .settings(0)),
            ReviewPreviewCase("settings-account-disconnected", .settings(0), state: AppFeature.State()),
            preview("settings-account-connecting", .settings(0)) {
                $0.apiKey = "fictional-preview-key"; $0.workID = UUID(0); $0.showsProgress = true
            },
            preview("settings-account-error", .settings(0)) {
                $0.error = "Couldn't connect to Solidtime. Check your address and API key, then try again."
            },
            preview("settings-account-disconnect-confirmation", .settings(0)) {
                $0.destination = .disconnect(AppFeature.disconnectConfirmation())
            }
        ]
        var dark = preview("settings-account-dark", .settings(0))
        dark.dark = true
        cases.append(dark)
        return cases
    }

    func trackingCases() -> [ReviewPreviewCase] {
        [
            preview("settings-tracking", .settings(1)),
            ReviewPreviewCase("settings-tracking-disconnected", .settings(1), state: AppFeature.State()),
            preview("settings-tracking-updating", .settings(1)) { $0.workID = UUID(0); $0.showsProgress = true },
            preview("settings-tracking-error", .settings(1)) {
                $0.error = "Couldn't load your organization. Refresh your entries to try again."
            }
        ]
    }

    func menuSettingsCases() -> [ReviewPreviewCase] {
        [MenuBarDisplay.elapsed, .today, .week, .indicator, .clock].map { display in
            preview("settings-menubar-\(display.rawValue)", .settings(2)) {
                $0.preferences.menuBarDisplay = display
            }
        }
    }

    func generalCases() -> [ReviewPreviewCase] {
        [
            preview("settings-general", .settings(3)),
            preview("settings-general-enabled", .settings(3)) { $0.generalSettings.status = .enabled },
            preview("settings-general-approval", .settings(3)) { $0.generalSettings.status = .requiresApproval },
            preview("settings-general-unavailable", .settings(3)) { $0.generalSettings.status = .unavailable },
            preview("settings-general-updating", .settings(3)) {
                $0.generalSettings.requestedEnabled = true; $0.generalSettings.showsProgress = true
            },
            preview("settings-general-error", .settings(3)) {
                $0.generalSettings.error = String(localized: .loginItemUpdateFailed)
            },
            preview("settings-updates-unavailable", .settings(3)) { $0.generalSettings.updates.status = UpdateStatus()
            },
            preview("settings-updates-checking", .settings(3)) {
                $0.generalSettings.updates.status = UpdateStatus(
                    isAvailable: true,
                    canCheck: false,
                    automaticallyChecks: true
                )
            },
            preview("settings-updates-auto-install", .settings(3)) {
                $0.generalSettings.updates.status = UpdateStatus(isAvailable: true, canCheck: true,
                                                                 automaticallyChecks: true, automaticallyInstalls: true)
            }
        ]
    }

    func generalBottomCases() -> [ReviewPreviewCase] {
        generalCases()
            .filter { ["settings-general", "settings-general-approval", "settings-general-error"].contains($0.name) }
            .map { original in
                var item = ReviewPreviewCase(original.name + "-bottom", original.screen, state: original.state)
                item.scroll = 1
                return item
            }
    }

    func workspaceSettingsCases() -> [ReviewPreviewCase] {
        var bottom = preview("settings-workspace-bottom", .settings(4))
        bottom.scroll = 1
        return [
            preview("settings-workspace", .settings(4)), bottom,
            preview("settings-workspace-targets-off", .settings(4)) {
                $0.preferences.workspace.dailyGoalHours = 0; $0.preferences.workspace.weeklyGoalHours = 0
            },
            preview("settings-workspace-custom-lunch", .settings(4)) {
                $0.preferences.workspace.lunchWindow = LunchWindow(startMinute: 12 * 60, endMinute: 14 * 60)
                $0.preferences.workspace.idleReminderMinutes = 10; $0.preferences.workspace.longTimerReminderHours = 3
            }
        ]
    }

    func rateSettingsCases() -> [ReviewPreviewCase] {
        [
            preview("settings-earnings-locked", .settings(5)),
            ReviewPreviewCase("settings-earnings-disconnected", .settings(5), state: AppFeature.State()),
            preview("settings-earnings-verifying", .settings(5)) {
                $0.earnings.pendingSurface = .settings; $0.earnings.operation = UUID(0); $0.earnings
                    .showsProgress = true
            },
            preview("settings-earnings-auth-error", .settings(5)) {
                $0.earnings.error = String(localized: .earningsTouchIdFailed)
            },
            preview("settings-earnings-unlocked", .settings(5)) { unlocked(&$0, surface: .settings) },
            preview("settings-earnings-unsaved", .settings(5)) {
                unlocked(&$0, surface: .settings); $0.earnings.settings?.hourlyRate = 30
            },
            preview("settings-earnings-saving", .settings(5)) {
                unlocked(&$0, surface: .settings); $0.earnings.operation = UUID(0); $0.earnings.showsProgress = true
            },
            preview("settings-earnings-save-error", .settings(5)) {
                unlocked(&$0, surface: .settings); $0.earnings.settings?.hourlyRate = 30
                $0.earnings.error = String(localized: .earningsSaveFailed)
            },
            preview("settings-earnings-invalid", .settings(5)) {
                unlocked(&$0, surface: .settings); $0.earnings.settings?.hourlyRate = -25
                $0.earnings.error = String(localized: .earningsValidRate)
            }
        ].map { item in
            var item = item
            item.state.preferences.workspace.earningsEnabled = true
            return item
        }
    }
}
