import AppKit
import ComposableArchitecture
@testable import FluidtimeCore

extension ReviewPreviewFixtures {
    func runtimeCases() throws -> [ReviewPreviewCase] {
        try runtimeWindowCases() + runtimeSettingsCases() + runtimeStressCases() + timerBannerCases()
    }

    private func timerBannerCases() -> [ReviewPreviewCase] {
        [640, 820, 1040].flatMap { width in
            [true, false].map { running in
                let name = "timer-banner-\(running ? "running" : "idle")-\(width)"
                var item = preview(name, .main) {
                    if !running {
                        $0.data.active = nil
                        $0.data.entries.removeFirst()
                        $0.description = ""
                    }
                }
                item.size = NSSize(width: width, height: 620)
                item.dark = width == 820
                return item
            }
        }
    }

    private func runtimeWindowCases() -> [ReviewPreviewCase] {
        var cases: [ReviewPreviewCase] = []
        for tab in WorkspaceFeature.Tab.allCases {
            for width in [640, 820, 1040] {
                var item = preview("runtime-\(tab.rawValue)-\(width)", .main) { $0.workspace.tab = tab }
                item.size = NSSize(width: width, height: 620)
                cases.append(item)
                item.state.workspace.showsSidebar = false
                cases.append(copy(item, name: item.name + "-detail"))
            }
        }
        for tab in WorkspaceFeature.Tab.allCases {
            var item = preview("runtime-minimum-\(tab.rawValue)", .main) {
                $0.workspace.tab = tab
                $0.workspace.history.period = .custom
            }
            item.size = NSSize(width: 640, height: 560)
            cases.append(item)
        }
        var loading = AppFeature.State()
        loading.lifecycle = .restoring(UUID(0))
        cases.append(ReviewPreviewCase("runtime-account-loading", .main, state: loading))
        loading.showsProgress = true
        cases.append(ReviewPreviewCase("runtime-account-loading-delayed", .main, state: loading))
        return cases
    }

    private func runtimeSettingsCases() -> [ReviewPreviewCase] {
        var cases: [ReviewPreviewCase] = []
        for index in 0 ... 5 {
            var item = preview("runtime-settings-\(index)", .settingsContent(index))
            if index == 5 {
                item.state.preferences.workspace.earningsEnabled = true
                unlocked(&item.state, surface: .settings)
                item.state.earnings.settings?.hourlyRate = 30
                item.state.earnings.error = String(localized: .earningsSaveFailed)
            }
            cases.append(item)
            item.dark = true
            cases.append(copy(item, name: item.name + "-dark"))
        }
        var projects = preview("runtime-project-visibility", .projectVisibility)
        projects.size = NSSize(width: 540, height: 460)
        cases.append(projects)
        return cases
    }

    private func runtimeStressCases() throws -> [ReviewPreviewCase] {
        var cases: [ReviewPreviewCase] = []
        for source in try editorCases() where ["editor-long-description", "editor-error"].contains(source.name) {
            var item = copy(source, name: "runtime-" + source.name + "-minimum")
            item.size = NSSize(width: 400, height: 320)
            item.editor?.error = String(localized: .editorInvalidDates)
            cases.append(item)
            item.scroll = 1
            cases.append(copy(item, name: item.name + "-bottom"))
        }
        var short = preview("runtime-history-short", .main) {
            $0.workspace.tab = .history
            $0.workspace.history.period = .custom
            $0.workspace.showsSidebar = false
            $0.error = String(localized: .solidtimeDidntReturnTheNumberOfTimeEntries)
        }
        short.size = NSSize(width: 640, height: 560)
        cases.append(short)
        var large = preview("runtime-earnings-large", .main) {
            $0.preferences.workspace.earningsEnabled = true
            unlocked(&$0, surface: .preview)
            $0.earnings.settings?.hourlyRate = 123_456_789.5
        }
        large.scroll = 1
        cases.append(large)
        return cases
    }

    private func copy(_ item: ReviewPreviewCase, name: String) -> ReviewPreviewCase {
        var result = ReviewPreviewCase(name, item.screen, state: item.state)
        result.size = item.size
        result.dark = item.dark
        result.scroll = item.scroll
        result.editor = item.editor
        return result
    }
}
