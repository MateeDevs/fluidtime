import ComposableArchitecture
import Foundation

@Reducer
struct UpdatesFeature {
    @ObservableState
    struct State: Equatable {
        var status = UpdateStatus()
    }

    enum Action: ViewAction, Equatable {
        case view(View)
        case statusChanged(UpdateStatus)
    }

    enum View: Equatable {
        case watch
        case check
        case openReleases
        case automaticChecksChanged(Bool)
        case automaticInstallationChanged(Bool)
    }

    @Dependency(\.updates) var updates
    @Dependency(\.system) var system

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.watch):
                return .run { [updates] send in
                    let statuses = await updates.statuses()
                    for await status in statuses {
                        try Task.checkCancellation()
                        await send(.statusChanged(status))
                    }
                }
            case let .statusChanged(status):
                state.status = status
                return .none
            case .view(.openReleases):
                guard let url = URL(string: "https://github.com/MateeDevs/fluidtime/releases") else { return .none }
                return .run { [system] _ in await system.openURL(url) }
            case .view(.check):
                guard state.status.isAvailable, state.status.canCheck else { return .none }
                return .run { [updates] _ in await updates.check() }
            case let .view(.automaticChecksChanged(value)):
                guard state.status.isAvailable else { return .none }
                return .run { [updates] _ in await updates.setAutomaticChecks(value) }
            case let .view(.automaticInstallationChanged(value)):
                guard state.status.isAvailable else { return .none }
                return .run { [updates] _ in await updates.setAutomaticInstallation(value) }
            }
        }
    }
}
