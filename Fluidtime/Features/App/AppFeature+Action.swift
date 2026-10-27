import ComposableArchitecture
import Foundation

extension AppFeature {
    @CasePathable
    enum Action: ViewAction, Equatable {
        case view(View)
        case interface(Interface)
        case generalSettings(GeneralSettingsFeature.Action)
        case workspace(WorkspaceFeature.Action)
        case earnings(EarningsFeature.Action)
        case reminderInputReceived(String, TimeInterval)
        case restored(UUID, AppPreferences, Result<Connection?, Failure>)
        case refreshRequested(full: Bool)
        case showProgress(UUID)
        case syncResponse(UUID, Result<SyncResponse, Failure>)
        case mutationResponse(UUID, Result<MutationResponse, Failure>)
        case timerShortcutResponse(UUID, Result<MutationResponse, Failure>)
        case timerStopped(UUID, TimeEntry)
        case deleteResponse(UUID, String, Result<Bool, Failure>)
        case disconnectResponse(UUID, Result<Bool, Failure>)
        case destination(PresentationAction<Destination.Action>)
    }

    struct SyncResponse: Equatable, Sendable {
        var connection: Connection
        var data: SessionData
        var isNewConnection: Bool
    }

    enum MutationResponse: Equatable, Sendable {
        case saved(TimeEntry)
        case existingTimer(TimeEntry)
    }
}

extension AppFeature.Action {
    @CasePathable
    enum View: BindableAction, Equatable {
        case binding(BindingAction<AppFeature.State>)
        case refreshTapped
        case selectMembership(String)
        case connectTapped
        case disconnectTapped
        case startRecent(TimeEntry)
        case startTapped
        case stopTapped
        case editTapped(TimeEntry, anchor: String? = nil)
        case settingsOpened
        case openInstanceTapped
        case quitTapped
        case openMainWindow
        case projectVisibilityChanged(String, isVisible: Bool)
        case allProjectsVisibilityChanged(isVisible: Bool)
        case workspacePreferencesChanged(WorkspacePreferences)
        case pinEntry(TimeEntry)
        case startPreset(TimerPreset)
        case removePreset(UUID)
        case dismissReminder
    }

    enum Interface: Equatable {
        case start
        case shutdown
        case toggleMenuBar
        case menuBarPresentationChanged(Bool)
        case settingsWindowOpenChanged(Bool)
        case mainWindowOpenChanged(Bool)
        case editorPresentationChanged(Bool)
        case toggleTimer
        case openPrimaryInterface
    }
}
