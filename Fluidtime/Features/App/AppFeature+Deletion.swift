import ComposableArchitecture
import Foundation

extension AppFeature {
    func requestEntryDeletion(_ entry: TimeEntry, state: inout State) -> Effect<Action> {
        guard state.canChangeAccount, state.connection != nil,
              state.data.entries.contains(entry) else { return .none }
        do {
            _ = try state.data.ownedMembership(for: entry)
            state.destination = .deleteEntry(Self.entryDeletionConfirmation(entry))
        } catch { state.error = error.localizedDescription }
        return .none
    }

    static func entryDeletionConfirmation(_ entry: TimeEntry) -> ConfirmationDialogState<Destination.DeleteEntry> {
        ConfirmationDialogState(titleVisibility: .visible) {
            TextState(.entryDelete)
        } actions: {
            ButtonState(role: .destructive, action: .confirm(entry)) { TextState(.entryDelete) }
            ButtonState(role: .cancel) { TextState(.cancel) }
        } message: {
            TextState(entry.title + "\n\n" + String(localized: entry.end == nil
                    ? .entryDeleteRunningHelp : .entryDeleteHelp))
        }
    }

    func deleteEntry(_ entry: TimeEntry, state: inout State) -> Effect<Action> {
        guard !state.isBusy, state.destination?.deleteEntry != nil, let connection = state.connection,
              state.data.entries.contains(entry) else { return .none }
        do {
            _ = try state.data.ownedMembership(for: entry)
        } catch {
            state.destination = nil
            state.error = error.localizedDescription
            return .none
        }
        state.destination = nil
        let id = beginWork(&state)
        return work(id: id) { [client] send in
            do {
                let active = try await client.activeEntry(connection)
                try Task.checkCancellation()
                guard entry.end == nil ? active?.id == entry.id : active?.id != entry.id else {
                    throw AppError.message(String(localized: .entryDeleteChanged))
                }
                try await client.delete(connection, entry)
                try Task.checkCancellation()
                await send(.deleteResponse(id, entry.id, .success(true)))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.deleteResponse(id, entry.id, .failure(Failure(error))))
            }
        }
    }

    func handleEntryDeletion(
        id: UUID, entryID: String, result: Result<Bool, Failure>, state: inout State
    ) -> Effect<Action> {
        guard state.workID == id else { return .none }
        finishWork(&state)
        switch result {
        case .success:
            state.data.entries.removeAll { $0.id == entryID }
            if state.active?.id == entryID {
                state.data.active = nil
                state.reminder = nil
                state.description = ""
                state.projectId = ""
            }
            state.data.lastSynced = now
            state.data.lastFullSync = nil
        case let .failure(failure): state.error = failure.message
        }
        return .cancel(id: CancelID.progress)
    }
}
