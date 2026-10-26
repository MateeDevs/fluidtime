import ComposableArchitecture
@testable import FluidtimeCore
import Foundation

/// Accepts local field bindings but never executes application effects or system clients.
struct ReviewPreviewReducer: Reducer {
    typealias State = AppFeature.State
    typealias Action = AppFeature.Action

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            if case let .workspace(.view(.historyInputChanged(input))) = action {
                state.workspace.historyPresentation = try? HistoryPresentation.make(input, at: Date())
            }
            return .none
        }
        BindingReducer<AppFeature.State, AppFeature.Action, AppFeature.Action.View>(action: \.view)
        Scope(state: \AppFeature.State.workspace, action: \.workspace) {
            BindingReducer<WorkspaceFeature.State, WorkspaceFeature.Action, WorkspaceFeature.View>(action: \.view)
        }
    }
}
