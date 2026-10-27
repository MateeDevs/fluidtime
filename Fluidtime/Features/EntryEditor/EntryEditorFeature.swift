import ComposableArchitecture
import Foundation

@Reducer
struct EntryEditorFeature {
    @ObservableState
    struct State: Equatable {
        var draft: EntryDraft
        let entry: TimeEntry
        let connection: Connection
        let membership: Membership
        let projects: [Project]
        var hiddenProjectIDs: Set<String> = []
        var presentationAnchor: String?

        var selectableProjects: [Project] {
            projects.filter { !hiddenProjectIDs.contains($0.id) }
        }

        var isSaving = false
        var showsProgress = false
        var error: String?

        var billable: Bool {
            if let override = draft.billableOverride {
                return override
            }
            return draft.projectId == (entry.projectId ?? "")
                ? entry.billable : projects.first { $0.id == draft.projectId }?.isBillable ?? false
        }
    }

    enum Action: ViewAction, Equatable {
        case view(View)
        case showProgress
        case saveResponse(Result<TimeEntry, Failure>)
        case delegate(Delegate)
    }

    @Dependency(\.solidtime) var client
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.date.now) var now
    private enum CancelID { case save, progress }

    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        Reduce { state, action in
            switch action {
            case .view(.binding): return .none
            case let .view(.projectChanged(id)):
                state.draft.projectId = id
                state.draft.billableOverride = nil
                return .none
            case let .view(.billableChanged(billable)):
                state.draft.billableOverride = billable
                return .none
            case .view(.saveTapped):
                guard !state.isSaving else { return .none }
                do {
                    guard state.draft.start <= now,
                          state.draft.end.map({ $0 > state.draft.start && $0 <= now }) ?? true
                    else {
                        throw AppError.message(String(localized: .editorInvalidDates))
                    }
                    guard state.draft.description.count <= 5000 else {
                        throw AppError.message(String(localized: .keepTheDescriptionUnder5000Characters))
                    }
                    let project: Project?
                    if state.draft.projectId == (state.entry.projectId ?? "") {
                        project = nil // Unchanged projects preserve billability and tasks.
                    } else if state.draft.projectId.isEmpty {
                        project = nil
                    } else {
                        guard let selected = state.projects.first(where: { $0.id == state.draft.projectId }) else {
                            throw AppError.message(String(localized: .chooseAnAvailableProjectBeforeSaving))
                        }
                        project = selected
                    }
                    state.isSaving = true
                    state.error = nil
                    let connection = state.connection
                    let update = EntryUpdate(
                        entry: state.entry, memberId: state.membership.id, change: .edit(state.draft, project)
                    )
                    return .merge(
                        .run { [client] send in
                            do {
                                let active = try await client.activeEntry(connection)
                                try Task.checkCancellation()
                                guard update.entry.end == nil ? active?.id == update.entry.id : active?.id != update
                                    .entry.id
                                else {
                                    throw AppError.message(String(localized: .editorTimerChanged))
                                }
                                let entry = try await client.update(connection, update)
                                try Task.checkCancellation()
                                await send(.saveResponse(.success(entry)))
                            } catch {
                                guard !Task.isCancelled else { return }
                                await send(.saveResponse(.failure(Failure(error))))
                            }
                        }.cancellable(id: CancelID.save, cancelInFlight: true),
                        .run { [clock] send in
                            try await clock.sleep(for: .seconds(2))
                            await send(.showProgress)
                        }.cancellable(id: CancelID.progress)
                    )
                } catch {
                    state.error = error.localizedDescription
                    return .none
                }
            case .view(.cancelTapped):
                guard !state.isSaving else { return .none }
                return .run { [dismiss] _ in await dismiss() }
            case .showProgress:
                if state.isSaving {
                    state.showsProgress = true
                }
                return .none
            case let .saveResponse(result):
                state.isSaving = false
                state.showsProgress = false
                switch result {
                case let .success(entry):
                    return .concatenate(.cancel(id: CancelID.progress), .send(.delegate(.saved(entry))))
                case let .failure(error):
                    state.error = error.message
                    return .cancel(id: CancelID.progress)
                }
            case .delegate: return .none
            }
        }
    }
}

extension EntryEditorFeature.Action {
    @CasePathable
    enum View: BindableAction, Equatable {
        case binding(BindingAction<EntryEditorFeature.State>)
        case saveTapped
        case cancelTapped
        case projectChanged(String)
        case billableChanged(Bool)
    }

    enum Delegate: Equatable { case saved(TimeEntry) }
}
