import ComposableArchitecture
import Foundation

@Reducer
struct GeneralSettingsFeature {
    @ObservableState
    struct State: Equatable {
        var updates = UpdatesFeature.State()
        var status: LaunchAtLoginStatus?
        var requestedEnabled: Bool?
        var showsProgress = false
        var error: String?

        var launchAtLogin: Bool {
            requestedEnabled ?? status?.isRegistered ?? false
        }

        var isUpdating: Bool {
            requestedEnabled != nil
        }
    }

    enum Action: ViewAction, Equatable {
        case view(View)
        case updates(UpdatesFeature.Action)
        case statusReceived(LaunchAtLoginStatus)
        case changeFinished(LaunchAtLoginStatus, Failure?)
        case showProgress
    }

    @Dependency(\.loginItem) var client
    @Dependency(\.continuousClock) var clock
    private enum CancelID { case status, progress }

    var body: some ReducerOf<Self> {
        Scope(state: \.updates, action: \.updates) { UpdatesFeature() }
        Reduce { state, action in
            switch action {
            case .view(.appeared), .view(.applicationBecameActive):
                guard !state.isUpdating else { return .none }
                return .run { [client] send in
                    let status = await client.status()
                    try Task.checkCancellation()
                    await send(.statusReceived(status))
                }.cancellable(id: CancelID.status, cancelInFlight: true)
            case let .statusReceived(status):
                guard !state.isUpdating else { return .none }
                if state.status != status {
                    state.error = nil
                }
                state.status = status
                return .none
            case let .view(.launchAtLoginChanged(enabled)):
                guard !state.isUpdating, let status = state.status,
                      status != .unavailable, enabled != status.isRegistered
                else { return .none }
                state.requestedEnabled = enabled
                state.error = nil
                return .merge(
                    .cancel(id: CancelID.status),
                    .run { [client] send in
                        var failure: Failure?
                        do {
                            try await client.setEnabled(enabled)
                        } catch {
                            failure = Failure(error)
                        }
                        let status = await client.status()
                        await send(.changeFinished(status, failure))
                    },
                    .run { [clock] send in
                        try await clock.sleep(for: .seconds(2))
                        await send(.showProgress)
                    }.cancellable(id: CancelID.progress)
                )
            case let .changeFinished(status, failure):
                let applied = state.requestedEnabled == status.isRegistered
                state.status = status
                state.requestedEnabled = nil
                state.showsProgress = false
                state.error = failure != nil && !applied ? String(localized: .loginItemUpdateFailed) : nil
                return .cancel(id: CancelID.progress)
            case .showProgress:
                state.showsProgress = state.isUpdating
                return .none
            case .view(.openLoginItemsSettingsTapped):
                return .run { [client] _ in await client.openSettings() }
            case .updates: return .none
            }
        }
    }
}

extension GeneralSettingsFeature.Action {
    @CasePathable
    enum View: Equatable {
        case appeared
        case applicationBecameActive
        case launchAtLoginChanged(Bool)
        case openLoginItemsSettingsTapped
    }
}
