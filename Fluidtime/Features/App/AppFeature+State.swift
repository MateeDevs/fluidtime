import ComposableArchitecture
import Foundation

extension AppFeature {
    @ObservableState
    struct State: Equatable {
        var generalSettings = GeneralSettingsFeature.State()
        var workspace = WorkspaceFeature.State()
        var earnings = EarningsFeature.State()
        var data = SessionData()
        var connection: Connection?
        var preferences = AppPreferences()
        var instanceAddress = "https://app.solidtime.io"
        var apiKey = ""
        var description = ""
        var projectId = ""
        var error: String?
        var workID: UUID?
        var showsProgress = false
        var isMenuBarPresented = false
        var isSettingsWindowOpen = false
        var isMainWindowOpen = false
        var isEditorPresented = false
        var reminder: TimerReminder?
        var remindedEntryId: String?
        var remindedKinds: Set<TimerReminder> = []
        var lifecycle = Lifecycle.stopped
        @Presents var destination: Destination.State?

        var isBusy: Bool {
            lifecycle.isRestoring || workID != nil || destination?.editor?.isSaving == true
        }

        var canChangeAccount: Bool {
            !isBusy && destination == nil
        }

        var isLoadingAccount: Bool {
            !isConnected && (lifecycle.isRestoring || workID != nil)
        }

        var isConfigured: Bool {
            connection != nil
        }

        var isConnected: Bool {
            connection != nil && data.user != nil
        }

        var menuBarDisplay: MenuBarDisplay {
            get { preferences.menuBarDisplay }
            set { preferences.menuBarDisplay = newValue }
        }

        var menuBarUsesProjectColor: Bool {
            get { preferences.menuBarUsesProjectColor }
            set { preferences.menuBarUsesProjectColor = newValue }
        }

        var menuBarShowsSeconds: Bool {
            get { preferences.menuBarShowsSeconds }
            set { preferences.menuBarShowsSeconds = newValue }
        }

        var user: SolidtimeUser? {
            data.user
        }

        var memberships: [Membership] {
            data.memberships
        }

        var selectedMembershipId: String {
            data.selectedMembershipId
        }

        var availableProjects: [Project] {
            data.availableProjects
        }

        var active: TimeEntry? {
            data.active
        }

        var activeInAnotherOrganization: Bool {
            data.activeInAnotherOrganization
        }

        var recentEntries: [TimeEntry] {
            data.recentEntries
        }

        var lastSynced: Date? {
            data.lastSynced
        }
    }

    enum Lifecycle: Equatable {
        case stopped
        case restoring(UUID)
        case running(UUID)

        var isRestoring: Bool {
            if case .restoring = self {
                return true
            }
            return false
        }
    }
}
