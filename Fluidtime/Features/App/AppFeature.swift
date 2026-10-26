import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @Dependency(\.solidtime) var client
    @Dependency(\.credentials) var credentials
    @Dependency(\.preferences) var preferences
    @Dependency(\.system) var system
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    enum CancelID { case lifecycle, work, progress }

    var body: some ReducerOf<Self> {
        Scope(state: \.generalSettings, action: \.generalSettings) { GeneralSettingsFeature() }
        Scope(state: \.workspace, action: \.workspace) { WorkspaceFeature() }
        Scope(state: \.earnings, action: \.earnings) { EarningsFeature() }
        BindingReducer(action: \.view)
        Reduce { state, action in
            switch action {
            case .view(.binding(\.menuBarDisplay)):
                let display = state.menuBarDisplay
                return .run { _ in preferences.setMenuBarDisplay(display) }
            case .view(.binding(\.menuBarUsesProjectColor)):
                let usesProjectColor = state.menuBarUsesProjectColor
                return .run { _ in preferences.setMenuBarUsesProjectColor(usesProjectColor) }
            case .view(.binding(\.menuBarShowsSeconds)):
                let showsSeconds = state.menuBarShowsSeconds
                return .run { _ in preferences.setMenuBarShowsSeconds(showsSeconds) }
            case .view(.binding): return .none
            case let .interface(action):
                return handleInterface(action, state: &state)
            case .view(.settingsOpened):
                state.isMenuBarPresented = false
                return .none
            case let .restored(id, saved, result):
                guard state.lifecycle == .restoring(id) else { return .none }
                state.lifecycle = .running(id)
                state.preferences = saved
                state.instanceAddress = saved.instance
                switch result {
                case let .success(connection):
                    state.connection = connection
                    return refresh(&state, full: true)
                case let .failure(error):
                    state.error = error.message
                    return .none
                }
            case .view(.refreshTapped):
                return refresh(&state, full: true)
            case let .refreshRequested(full):
                return refresh(&state, full: full)
            case let .view(.selectMembership(id)):
                guard state.canChangeAccount, id != state.selectedMembershipId,
                      state.memberships.contains(where: { $0.id == id })
                else { return .none }
                let cancelPrivateOperation = state.earnings.operation != nil
                state.workspace = WorkspaceFeature.State()
                state.data.selectedMembershipId = id
                state.data.clearEntries()
                state.description = ""
                state.projectId = ""
                state.preferences.membershipId = id
                state.earnings = EarningsFeature.State(accountScope: state.accountScope)
                state.destination = nil
                return .concatenate(
                    cancelPrivateOperation ? .send(.earnings(.interface(.lock))) : .none,
                    .run { [preferences] _ in preferences.setMembership(id) },
                    refresh(&state, full: true)
                )
            case .view(.connectTapped):
                guard state.canChangeAccount else { return .none }
                do {
                    let connection = try Connection(instance: state.instanceAddress, token: state.apiKey)
                    let id = beginWork(&state)
                    let preferred = state.preferences.membershipId
                    let date = now
                    return work(id: id) { [client, credentials, preferences] send in
                        do {
                            let data = try await SessionSync(client: client).fetch(
                                connection: connection, previous: SessionData(),
                                preferredMembershipId: preferred, full: true, now: date
                            )
                            try Task.checkCancellation()
                            try credentials.save(connection)
                            preferences.setInstance(connection.instance.absoluteString)
                            await send(
                                .syncResponse(
                                    id,
                                    .success(SyncResponse(connection: connection, data: data, isNewConnection: true))
                                )
                            )
                        } catch {
                            guard !Task.isCancelled else { return }
                            await send(.syncResponse(id, .failure(Failure(error))))
                        }
                    }
                } catch {
                    state.error = error.localizedDescription
                    return .none
                }
            case .view(.disconnectTapped):
                guard state.canChangeAccount, state.isConfigured else { return .none }
                state.destination = .disconnect(Self.disconnectConfirmation())
                return .none
            case .destination(.presented(.disconnect(.confirm))):
                guard !state.isBusy, let connection = state.connection else { return .none }
                state.destination = nil
                let id = beginWork(&state)
                return work(id: id) { [credentials] send in
                    do {
                        try credentials.delete(connection.instance)
                        await send(.disconnectResponse(id, .success(true)))
                    } catch { await send(.disconnectResponse(id, .failure(Failure(error)))) }
                }
            case let .disconnectResponse(id, result):
                guard state.workID == id else { return .none }
                let cancelPrivateOperation = state.earnings.operation != nil
                finishWork(&state)
                switch result {
                case .success:
                    state.connection = nil
                    state.earnings = EarningsFeature.State()
                    state.data = SessionData()
                    state.workspace = WorkspaceFeature.State()
                    state.description = ""
                    state.projectId = ""
                    state.apiKey = ""
                    state.destination = nil
                case let .failure(error): state.error = error.message
                }
                return .merge(.cancel(id: CancelID.progress),
                              cancelPrivateOperation && state
                                  .connection == nil ? .send(.earnings(.interface(.lock))) : .none)
            case let .syncResponse(id, result):
                guard state.workID == id else { return .none }
                finishWork(&state)
                switch result {
                case let .success(response):
                    let cancelPrivateOperation = applySyncResponse(response, to: &state)
                    return .merge(.cancel(id: CancelID.progress), checkReminders(state),
                                  cancelPrivateOperation ? .send(.earnings(.interface(.lock))) : .none)
                case let .failure(error): state.error = error.message
                }
                return .cancel(id: CancelID.progress)
            case let .view(.startRecent(entry)):
                guard state.canChangeAccount else { return .none }
                useRecent(entry, state: &state)
                return startTimer(&state, stoppingActiveEntry: true)
            case .view(.startTapped):
                return startTimer(&state)
            case .view(.stopTapped):
                return stopTimer(&state)
            case let .timerStopped(id, entry):
                guard state.workID == id else { return .none }
                state.data.applyStoppedTimer(entry, at: now)
                return .none
            case let .mutationResponse(id, result):
                return handleMutation(id: id, result: result, state: &state)
            case let .showProgress(id):
                if state.workID == id {
                    state.showsProgress = true
                }
                return .none
            case let .view(.editTapped(entry, anchor)):
                return editEntry(entry, anchor: anchor, state: &state)
            case let .destination(.presented(.editor(.delegate(.saved(entry))))):
                state.data.apply(entry, at: now)
                state.reminder = nil
                if state.active?.id == entry.id {
                    state.description = entry.description ?? ""
                    state.projectId = entry.projectId ?? ""
                }
                state.destination = nil
                return state.isEditorPresented ? .run { [system] _ in await system.closeEntryEditor() } : .none
            case .destination(.dismiss):
                return state.isEditorPresented ? .run { [system] _ in await system.closeEntryEditor() } : .none
            case let .destination(.presented(.deleteEntry(.confirm(entry)))):
                return deleteEntry(entry, state: &state)
            case let .deleteResponse(id, entryID, result):
                return handleEntryDeletion(id: id, entryID: entryID, result: result, state: &state)
            case .destination, .generalSettings, .earnings: return .none
            case let .workspace(.delegate(action)):
                return handleWorkspaceDelegate(action, state: &state)
            case .workspace(.view(.appeared)):
                if let navigation = state.preferences.workspace.navigation[state.accountScope] {
                    state.workspace.tab = WorkspaceFeature.Tab(rawValue: navigation.destination) ?? .overview
                }
                return .none
            case .workspace(.view(.binding(\.tab))),
                 .workspace(.view(.find)):
                guard !state.accountScope.isEmpty else { return .none }
                state.preferences.workspace.navigation[state.accountScope] = WorkspaceNavigation(
                    destination: (state.workspace.tab ?? .overview).rawValue
                )
                return .merge(persistWorkspace(state), concealOverviewEarningsIfNeeded(state))
            case .workspace: return .none
            case let .reminderInputReceived(id, seconds):
                return handleReminder(entryId: id, idleSeconds: seconds, state: &state)
            case let .view(.projectVisibilityChanged(id, isVisible)):
                return setProjectVisibility([id], isVisible: isVisible, state: &state)
            case let .view(.allProjectsVisibilityChanged(isVisible)):
                return setProjectVisibility(Set(state.availableProjects.map(\.id)), isVisible: isVisible, state: &state)
            case .view(.openMainWindow), .view(.workspacePreferencesChanged),
                 .view(.pinEntry), .view(.startPreset), .view(.removePreset),
                 .view(.dismissReminder):
                guard case let .view(viewAction) = action else { return .none }
                return handleWorkspaceAction(viewAction, state: &state)
            case .view(.openInstanceTapped):
                let address = state.connection?.instance.absoluteString ?? state.instanceAddress
                guard let connection = try? Connection(instance: address, token: "open") else { return .none }
                return .run { _ in await system.openURL(connection.instance) }
            case .view(.quitTapped):
                return .concatenate(shutdown(&state), .run { [system] _ in await system.quit() })
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
