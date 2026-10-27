import ComposableArchitecture
import Foundation

@Reducer
struct WorkspaceFeature {
    @Dependency(\.system) var system
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now

    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)
        Reduce { state, action in
            switch action {
            case .view(.binding(\.customStart)):
                if state.customStart > state.customEnd {
                    state.customEnd = state.customStart
                }
                return .none
            case .view(.binding(\.customEnd)):
                if state.customEnd < state.customStart {
                    state.customStart = state.customEnd
                }
                return .none
            case .view(.binding(\.history.start)):
                if state.history.start > state.history.end {
                    state.history.end = state.history.start
                }
                return .none
            case .view(.binding(\.history.end)):
                if state.history.end < state.history.start {
                    state.history.start = state.history.end
                }
                return .none
            case let .view(.historyInputChanged(input)):
                return prepareHistory(input, state: &state)
            case let .historyPrepared(id, presentation):
                guard state.historyRequestID == id else { return .none }
                state.historyRequestID = nil
                state.historyPresentation = presentation
                return .none
            case .view(.toggleSidebar):
                state.showsSidebar.toggle()
                return .none
            case .view(.find):
                state.tab = .history
                state.searchFocusRequest += 1
                return .none
            case .view(.binding):
                return .none
            case let .view(.appeared(scope, calendar)):
                state.accountScope = scope
                state.calendar = calendar
                if state.customStart == .distantPast {
                    state.customStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
                    state.customEnd = now
                    state.history.start = state.customStart
                    state.history.end = now
                }
                return .none
            case let .view(.deleteTapped(entry)): return .send(.delegate(.delete(entry)))
            case let .view(.editTapped(entry, anchor)): return .send(.delegate(.edit(entry, anchor: anchor)))
            case let .view(.startTapped(entry)): return .send(.delegate(.start(entry)))
            case let .view(.pinTapped(entry)): return .send(.delegate(.pin(entry)))
            case let .view(.export(document)):
                state.exportError = nil
                return .run { [system] send in
                    do {
                        _ = try await system.exportCSV(document)
                        await send(.exportFinished(nil))
                    } catch { await send(.exportFinished(Failure(error))) }
                }
            case let .exportFinished(failure):
                state.exportError = failure == nil ? nil : String(localized: .exportFailed)
                return .none
            case .delegate: return .none
            }
        }
    }
}
