import ComposableArchitecture
import Foundation

extension AppFeature {
    func applySyncResponse(_ response: SyncResponse, to state: inout State) -> Bool {
        let previousScope = state.accountScope
        let hadPrivateOperation = state.earnings.operation != nil
        let timerChanged = state.active?.id != response.data.active?.id
        if timerChanged {
            state.reminder = nil
            state.remindedEntryId = nil
            state.remindedKinds = []
        }
        if timerChanged || state.lastSynced == nil || response.isNewConnection {
            state.description = response.data.active?.description ?? ""
            state.projectId = response.data.active?.projectId ?? ""
        }
        state.connection = response.connection
        state.data = response.data
        if previousScope != state.accountScope {
            state.workspace = WorkspaceFeature.State()
            state.earnings = EarningsFeature.State(accountScope: state.accountScope)
        }
        if response.isNewConnection {
            state.preferences.instance = response.connection.instance.absoluteString
            state.instanceAddress = response.connection.instance.absoluteString
            state.apiKey = ""
            state.destination = nil
        }
        return previousScope != state.accountScope && hadPrivateOperation
    }

    func refresh(_ state: inout State, full: Bool) -> Effect<Action> {
        guard !state.isBusy, state.destination == nil, let connection = state.connection else { return .none }
        let id = beginWork(&state)
        let previous = state.data
        let preferred = state.preferences.membershipId
        let date = now
        return work(id: id) { [client] send in
            do {
                let data = try await SessionSync(client: client).fetch(
                    connection: connection, previous: previous,
                    preferredMembershipId: preferred, full: full, now: date
                )
                try Task.checkCancellation()
                await send(
                    .syncResponse(
                        id, .success(SyncResponse(connection: connection, data: data, isNewConnection: false))
                    )
                )
            } catch {
                guard !Task.isCancelled else { return }
                await send(.syncResponse(id, .failure(Failure(error))))
            }
        }
    }

    func startTimer(_ state: inout State, stoppingActiveEntry: Bool = false) -> Effect<Action> {
        @Dependency(\.date) var date
        guard !state.isBusy, state.destination == nil,
              let connection = state.connection, let membership = state.data.membership
        else { return .none }
        do {
            let description = state.description
            guard description.count <= 5000 else {
                throw AppError.message(String(localized: .keepTheDescriptionUnder5000Characters))
            }
            let project = try state.data.selectedProject(state.projectId)
            let requestedAt = now
            let data = state.data
            let id = beginWork(&state)
            return work(id: id) { [client, date] send in
                do {
                    let active = try await client.activeEntry(connection)
                    try Task.checkCancellation()
                    let startedAt = stoppingActiveEntry ? date.now : requestedAt
                    if let active {
                        guard stoppingActiveEntry else {
                            await send(.mutationResponse(id, .success(.existingTimer(active))))
                            return
                        }
                        let activeMembership = try data.ownedMembership(for: active)
                        let update = EntryUpdate(entry: active, memberId: activeMembership.id, change: .stop(startedAt))
                        let stopped = try await client.update(connection, update)
                        try Task.checkCancellation()
                        await send(.timerStopped(id, stopped))
                        try Task.checkCancellation()
                    }
                    let entry = try await client.create(connection, membership, description, project, startedAt)
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

    func shutdown(_ state: inout State) -> Effect<Action> {
        let cancelPrivateOperation = state.earnings.operation != nil
        state.earnings = EarningsFeature.State(accountScope: state.accountScope)
        state.lifecycle = .stopped
        state.workID = nil
        state.showsProgress = false
        state.destination = nil
        state.isMenuBarPresented = false
        return .merge(
            .cancel(id: CancelID.lifecycle), .cancel(id: CancelID.work), .cancel(id: CancelID.progress),
            cancelPrivateOperation ? .send(.earnings(.interface(.lock))) : .none
        )
    }

    func beginWork(_ state: inout State) -> UUID {
        let id = uuid()
        state.workID = id
        state.showsProgress = false
        state.error = nil
        return id
    }

    func finishWork(_ state: inout State) {
        state.workID = nil
        state.showsProgress = false
    }

    func work(id: UUID, operation: @escaping @Sendable (Send<Action>) async throws -> Void) -> Effect<Action> {
        .merge(
            .run(operation: operation).cancellable(id: CancelID.work),
            .run { [clock] send in
                try await clock.sleep(for: .seconds(2))
                await send(.showProgress(id))
            }.cancellable(id: CancelID.progress)
        )
    }

    func useRecent(_ entry: TimeEntry, state: inout State) {
        state.description = entry.description ?? ""
        state.projectId =
            state.availableProjects.contains(where: { $0.id == entry.projectId }) ? (entry.projectId ?? "") : ""
    }
}
