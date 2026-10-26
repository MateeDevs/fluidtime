import AppKit
import ComposableArchitecture
@testable import FluidtimeCore

extension ReviewPreviewFixtures {
    func navigationCases() -> [ReviewPreviewCase] {
        WorkspaceFeature.Tab.allCases.map { tab in
            preview("main-navigation-\(tab.rawValue)", .main) { $0.workspace.tab = tab }
        }
    }

    func stressCases() -> [ReviewPreviewCase] {
        [
            preview("settings-account-long-values", .settings(0)) {
                $0.instanceAddress = "https://solidtime.example.invalid/team/design-and-product/solidtime"
                $0.data.user = SolidtimeUser(
                    id: "preview-user",
                    name: "Alexandria Morgan-Wellington and the product team",
                    timezone: "Europe/Prague",
                    weekStart: "monday"
                )
            },
            preview("settings-tracking-long-organization", .settings(1)) {
                $0.data.memberships[0] = Membership(id: "member", organization: .init(
                    id: "studio", name: "International product design and engineering consulting studio"
                ))
            },
            preview("main-idle-long-project", .main) {
                $0.data.active = nil
                $0.data.entries.removeFirst()
                $0.data.projects[0] = Project(
                    id: "web",
                    name: "Website redesign and accessibility improvements for all regions",
                    color: "#18A970",
                    isArchived: false,
                    isBillable: true
                )
                $0.projectId = "web"
            },
            preview("main-earnings-large-value", .main) {
                $0.workspace.tab = .overview
                unlocked(&$0, surface: .preview)
                $0.earnings.settings?.hourlyRate = 123_456_789.5
            },
            preview("settings-general-approval-error", .settings(3)) {
                $0.generalSettings.status = .requiresApproval
                $0.generalSettings.error = String(localized: .loginItemUpdateFailed)
            }
        ]
    }
}
