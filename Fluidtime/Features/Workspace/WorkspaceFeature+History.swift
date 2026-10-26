import ComposableArchitecture
import Foundation

extension WorkspaceFeature {
    enum CancelID { case historyPreparation }

    func prepareHistory(_ input: HistoryPresentation.Input, state: inout State) -> Effect<Action> {
        let id = uuid()
        state.historyRequestID = id
        if state.historyPresentation?.scope != input.scope {
            state.historyPresentation = nil
        }
        return .run { [now] send in
            let presentation = try await HistoryPresentation.prepare(input, at: now)
            try Task.checkCancellation()
            await send(.historyPrepared(id, presentation))
        }
        .cancellable(id: CancelID.historyPreparation, cancelInFlight: true)
    }
}
