import ComposableArchitecture
import Foundation

extension EarningsFeature {
    func unlock(_ surface: Surface, state: inout State) -> Effect<Action> {
        let id = uuid()
        let scope = state.accountScope
        state.settings = nil
        state.savedSettings = nil
        state.surface = nil
        state.pendingSurface = surface
        state.operation = id
        state.error = nil
        return .merge(
            .run { [biometrics, earnings] send in
                do {
                    let authenticated = try await biometrics.authenticate()
                    try Task.checkCancellation()
                    let settings = try authenticated ? earnings.load(scope) : nil
                    try Task.checkCancellation()
                    await send(.unlockResponse(id, .success(settings)))
                } catch {
                    guard !Task.isCancelled else { return }
                    await send(.unlockResponse(id, .failure(Failure(error))))
                }
            }.cancellable(id: CancelID.operation, cancelInFlight: true),
            progress(id)
        )
    }

    func save(_ state: inout State) -> Effect<Action> {
        guard state.surface == .settings, state.operation == nil, state.hasChanges,
              let settings = state.settings else { return .none }
        guard !settings.hourlyRate.isNaN, settings.hourlyRate >= 0 else {
            state.error = String(localized: .earningsValidRate)
            return .none
        }
        let id = uuid()
        let scope = state.accountScope
        state.operation = id
        state.error = nil
        return .merge(
            .run { [earnings] send in
                do {
                    try Task.checkCancellation()
                    try earnings.save(scope, settings)
                    try Task.checkCancellation()
                    await send(.saveResponse(id, nil))
                } catch {
                    guard !Task.isCancelled else { return }
                    await send(.saveResponse(id, Failure(error)))
                }
            }.cancellable(id: CancelID.operation, cancelInFlight: true),
            progress(id)
        )
    }

    private func progress(_ id: UUID) -> Effect<Action> {
        .run { [clock] send in
            try await clock.sleep(for: .seconds(2))
            await send(.showProgress(id))
        }.cancellable(id: CancelID.progress, cancelInFlight: true)
    }
}
