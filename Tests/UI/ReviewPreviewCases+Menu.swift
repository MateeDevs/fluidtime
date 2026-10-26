import AppKit
import ComposableArchitecture
@testable import FluidtimeCore

extension ReviewPreviewFixtures {
    func menuCases() -> [ReviewPreviewCase] {
        let cases = [
            preview("menu-running", .menu),
            preview("menu-idle", .menu) { $0.data.active = nil; $0.data.entries.removeFirst() },
            ReviewPreviewCase("menu-welcome", .menu, state: AppFeature.State()),
            preview("menu-empty", .menu) { $0.data.active = nil; $0.data.entries = [] },
            preview("menu-unsynced", .menu) { $0.data.active = nil; $0.data.entries = []; $0.data.lastSynced = nil },
            preview("menu-updating", .menu) { $0.workID = UUID(0); $0.showsProgress = true },
            preview("menu-error", .menu) {
                $0.error = "Couldn't update your timer. Check your connection and try again."
            },
            preview("menu-other-organization", .menu) {
                $0.data.active = Self.entry(
                    "other",
                    start: now.addingTimeInterval(-1800),
                    end: nil,
                    organization: "other"
                )
            },
            preview("menu-long-description", .menu) {
                let entry = Self.entry("long", start: now.addingTimeInterval(-2700), end: nil,
                                       description: Self.longDescription)
                $0.data.active = entry
                $0.data.entries[0] = entry
            },
            preview("menu-pinned", .menu) {
                $0.preferences.workspace.presets = (0 ..< 4).map {
                    TimerPreset(id: UUID($0), scope: state.accountScope,
                                description: [
                                    "Design review",
                                    "Weekly planning",
                                    "Project administration",
                                    "Prototype updates"
                                ][$0],
                                projectId: "web")
                }
            },
            preview("menu-idle-reminder", .menu) { $0.reminder = .idle },
            preview("menu-long-reminder", .menu) { $0.reminder = .longRunning }
        ]
        return cases + additionalMenuCases(cases)
    }

    private func additionalMenuCases(_ cases: [ReviewPreviewCase]) -> [ReviewPreviewCase] {
        var error = AppFeature.State()
        error.error = "Couldn't connect to Solidtime. Check your address and API key, then try again."
        let original = cases.first { $0.name == "menu-pinned" }!
        var bottom = ReviewPreviewCase("menu-pinned-bottom", .menu, state: original.state)
        bottom.scroll = 1
        let errorState = cases.first { $0.name == "menu-error" }!.state
        var errorBottom = ReviewPreviewCase("menu-error-bottom", .menu, state: errorState)
        errorBottom.scroll = 1
        return [ReviewPreviewCase("menu-welcome-error", .menu, state: error), bottom, errorBottom]
    }

    func labelCases() -> [ReviewPreviewCase] {
        [MenuBarDisplay.elapsed, .today, .week, .indicator, .clock].flatMap { display in
            [true, false].flatMap { running in
                [true, false].map { seconds in
                    preview(
                        "label-\(display.rawValue)-\(running ? "running" : "idle")-\(seconds ? "seconds" : "minutes")",
                        .label
                    ) {
                        $0.preferences.menuBarDisplay = display
                        $0.preferences.menuBarShowsSeconds = seconds
                        if !running {
                            $0.data.active = nil; $0.data.entries.removeFirst()
                        }
                    }
                }
            }
        }
    }
}
