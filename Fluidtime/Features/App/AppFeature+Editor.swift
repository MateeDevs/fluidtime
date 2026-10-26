import ComposableArchitecture
import Foundation

extension AppFeature {
    func editEntry(_ entry: TimeEntry, anchor: String?, state: inout State) -> Effect<Action> {
        guard !state.isBusy, let connection = state.connection, state.destination == nil,
              state.data.entries.contains(where: { $0.id == entry.id }) else { return .none }
        do {
            let membership = try state.data.ownedMembership(for: entry)
            state.destination = .editor(EntryEditorFeature.State(
                draft: EntryDraft(entry: entry), entry: entry, connection: connection,
                membership: membership, projects: state.availableProjects, hiddenProjectIDs: state.hiddenProjectIDs,
                presentationAnchor: anchor
            ))
            return .run { [system] _ in await system.openEntryEditor(anchor) }
        } catch {
            state.error = error.localizedDescription
            return .none
        }
    }
}
