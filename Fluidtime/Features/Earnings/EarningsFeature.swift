import ComposableArchitecture
import Foundation

@Reducer
struct EarningsFeature {
    @Dependency(\.earnings) var earnings
    @Dependency(\.biometrics) var biometrics
    @Dependency(\.uuid) var uuid
    @Dependency(\.continuousClock) var clock
    enum CancelID { case operation, progress }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .interface(.contextChanged(scope)):
                guard state.accountScope != scope else { return .none }
                state = State(accountScope: scope)
                return cancellation
            case .interface(.lock): return lock(&state)
            case let .interface(.conceal(surface)), let .view(.conceal(surface)):
                guard state.surface == surface || state.pendingSurface == surface else { return .none }
                return lock(&state)
            case let .view(.reveal(surface)):
                guard !state.accountScope.isEmpty, state.operation == nil else { return .none }
                return unlock(surface, state: &state)
            case let .unlockResponse(id, result):
                guard state.operation == id else { return .none }
                let surface = state.pendingSurface
                state.operation = nil
                state.pendingSurface = nil
                state.showsProgress = false
                switch result {
                case let .success(settings):
                    state.settings = settings
                    state.savedSettings = settings
                    state.surface = settings == nil ? nil : surface
                case let .failure(failure): state.error = failure.message
                }
                return .cancel(id: CancelID.progress)
            case let .view(.rateChanged(value)):
                guard state.surface == .settings, state.operation == nil else { return .none }
                state.settings?.hourlyRate = value
                return .none
            case let .view(.currencyChanged(value)):
                guard state.surface == .settings, state.operation == nil else { return .none }
                state.settings?.currency = value
                return .none
            case .view(.save): return save(&state)
            case let .saveResponse(id, failure):
                guard state.operation == id else { return .none }
                state.operation = nil
                state.showsProgress = false
                if failure == nil {
                    state.savedSettings = state.settings
                }
                state.error = failure == nil ? nil : String(localized: .earningsSaveFailed)
                return .cancel(id: CancelID.progress)
            case let .showProgress(id):
                guard state.operation == id else { return .none }
                state.showsProgress = true
                return .none
            }
        }
    }

    private var cancellation: Effect<Action> {
        .merge(.cancel(id: CancelID.operation), .cancel(id: CancelID.progress))
    }

    private func lock(_ state: inout State) -> Effect<Action> {
        state = State(accountScope: state.accountScope)
        return cancellation
    }
}
