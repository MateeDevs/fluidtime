import ComposableArchitecture
import Foundation

extension WorkspaceFeature {
    @CasePathable
    enum Action: ViewAction, Equatable {
        case view(View)
        case exportFinished(Failure?)
        case historyPrepared(UUID, HistoryPresentation)
        case delegate(Delegate)
    }

    enum View: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case appeared(String, Calendar)
        case editTapped(TimeEntry, anchor: String? = nil)
        case deleteTapped(TimeEntry)
        case startTapped(TimeEntry)
        case pinTapped(TimeEntry)
        case export(CSVDocument)
        case find
        case historyInputChanged(HistoryPresentation.Input)
    }

    enum Delegate: Equatable {
        case edit(TimeEntry, anchor: String? = nil)
        case delete(TimeEntry)
        case start(TimeEntry)
        case pin(TimeEntry)
    }
}
