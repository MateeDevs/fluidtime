import ComposableArchitecture
import Foundation

extension AppFeature {
    func stopTimer(_ state: inout State) -> Effect<Action> {
        guard !state.isBusy, state.destination == nil, let connection = state.connection,
              let active = state.active else { return .none }
        do {
            let membership = try state.data.ownedMembership(for: active)
            let id = beginWork(&state)
            let date = now
            return work(id: id) { [client] send in
                do {
                    guard let running = try await client.activeEntry(connection), running.id == active.id else {
                        throw AppError
                            .message(String(localized: .yourRunningTimerChangedOnSolidtimeRefreshBeforeStoppingIt))
                    }
                    try Task.checkCancellation()
                    let update = EntryUpdate(entry: running, memberId: membership.id, change: .stop(date))
                    let entry = try await client.update(connection, update)
                    try Task.checkCancellation()
                    await send(.mutationResponse(id, .success(.saved(entry))))
                } catch {
                    guard !Task.isCancelled else { return }
                    await send(.mutationResponse(id, .failure(Failure(error))))
                }
            }
        } catch {
            state.error = error.localizedDescription
            return .none
        }
    }

    func toggleTimer(_ state: inout State) -> Effect<Action> {
        @Dependency(\.date) var date
        guard state.canChangeAccount, let connection = state.connection, let membership = state.data.membership else {
            return .none
        }
        let data = state.data
        let id = beginWork(&state)
        return work(id: id) { [client, date] send in
            do {
                let active = try await client.activeEntry(connection)
                try Task.checkCancellation()
                let timestamp = date.now
                let result: TimeEntry
                if let active {
                    let owner = try data.ownedMembership(for: active)
                    result = try await client.update(
                        connection,
                        EntryUpdate(entry: active, memberId: owner.id, change: .stop(timestamp))
                    )
                    try Task.checkCancellation()
                    await send(.timerStopped(id, result))
                } else {
                    guard let recent = data.recentEntries.first else {
                        throw AppError.message(String(localized: .timerNoRecentEntry))
                    }
                    let project = data.availableProjects.first { $0.id == recent.projectId }
                    result = try await client.create(
                        connection,
                        membership,
                        recent.description ?? "",
                        project,
                        timestamp
                    )
                }
                try Task.checkCancellation()
                await send(.timerShortcutResponse(id, .success(.saved(result))))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.timerShortcutResponse(id, .failure(Failure(error))))
            }
        }
    }

    func handleMutation(
        id: UUID, result: Result<MutationResponse, Failure>, state: inout State, isShortcut: Bool = false
    ) -> Effect<Action> {
        guard state.workID == id else { return .none }
        finishWork(&state)
        let feedback: TimerFeedback
        switch result {
        case let .success(.saved(entry)):
            state.data.apply(entry, at: now)
            state.reminder = nil
            feedback = entry.end == nil ? .started(entry) : .stopped(entry)
        case let .success(.existingTimer(active)):
            state.data.apply(active, at: now)
            state.error = String(localized: .youAlreadyHaveARunningTimerStopItBeforeStartingAnother)
            feedback = .failed
        case let .failure(error):
            state.error = error.message
            feedback = .failed
        }
        let announcement: Effect<Action> = state.preferences.workspace
            .timerFeedback && (isShortcut || feedback == .failed)
            ? .run { [system] _ in await system.showTimerFeedback(feedback) } : .none
        return .merge(.cancel(id: CancelID.progress), announcement)
    }
}
