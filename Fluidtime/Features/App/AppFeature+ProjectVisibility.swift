import ComposableArchitecture
import Foundation

extension AppFeature.State {
    var hiddenProjectIDs: Set<String> {
        preferences.projectVisibility.hiddenIDs(in: accountScope)
    }

    var selectableProjects: [Project] {
        let hidden = hiddenProjectIDs
        return availableProjects.filter { !hidden.contains($0.id) }
    }
}

extension AppFeature {
    func setProjectVisibility(_ ids: Set<String>, isVisible: Bool, state: inout State) -> Effect<Action> {
        guard state.canChangeAccount, !state.accountScope.isEmpty else { return .none }
        let availableIDs = Set(state.availableProjects.map(\.id))
        let changedIDs = ids.intersection(availableIDs)
        guard !changedIDs.isEmpty else { return .none }
        state.preferences.projectVisibility.setVisible(isVisible, projectIDs: changedIDs, in: state.accountScope)
        let value = state.preferences.projectVisibility
        return .run { [preferences] _ in preferences.setProjectVisibility(value) }
    }
}
