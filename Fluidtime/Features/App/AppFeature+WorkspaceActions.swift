import ComposableArchitecture
import Foundation

extension AppFeature {
    func handleWorkspaceAction(_ action: Action.View, state: inout State) -> Effect<Action> {
        switch action {
        case .openMainWindow:
            state.isMenuBarPresented = false
            return .run { [system] _ in await system.openMainWindow() }
        case let .workspacePreferencesChanged(value):
            var value = value
            value.dailyGoalHours = value.dailyGoalHours.isFinite ? max(0, min(value.dailyGoalHours, 24)) : 0
            value.weeklyGoalHours = value.weeklyGoalHours.isFinite ? max(0, min(value.weeklyGoalHours, 168)) : 0
            value.idleReminderMinutes = max(0, value.idleReminderMinutes)
            value.longTimerReminderHours = max(0, value.longTimerReminderHours)
            value.lunchWindow = value.lunchWindow.normalized
            state.preferences.workspace = value
            if !value.earningsEnabled {
                state.earnings = EarningsFeature.State(accountScope: state.accountScope)
                return .merge(persistWorkspace(state), .send(.earnings(.interface(.lock))))
            }
            return persistWorkspace(state)
        case let .pinEntry(entry):
            return togglePreset(entry, state: &state)
        case let .startPreset(preset):
            return startPreset(preset, state: &state)
        case let .removePreset(id):
            let scope = state.accountScope
            state.preferences.workspace.presets.removeAll { $0.id == id && $0.scope == scope }
            return persistWorkspace(state)
        case .dismissReminder:
            state.reminder = nil
            return .none
        default: return .none
        }
    }

    func handleWorkspaceDelegate(_ action: WorkspaceFeature.Delegate, state: inout State) -> Effect<Action> {
        switch action {
        case let .edit(entry, anchor): return editEntry(entry, anchor: anchor, state: &state)
        case let .delete(entry): return requestEntryDeletion(entry, state: &state)
        case let .pin(entry): return handleWorkspaceAction(.pinEntry(entry), state: &state)
        case let .start(entry):
            guard state.canChangeAccount else { return .none }
            useRecent(entry, state: &state)
            return startTimer(&state, stoppingActiveEntry: true)
        }
    }

    func concealOverviewEarningsIfNeeded(_ state: State) -> Effect<Action> {
        let isHidden = state.workspace.tab != .overview
        let hasPrivateState = state.earnings.surface == .preview || state.earnings.pendingSurface == .preview
        return isHidden && hasPrivateState ? .send(.earnings(.interface(.conceal(.preview)))) : .none
    }

    private func startPreset(_ preset: TimerPreset, state: inout State) -> Effect<Action> {
        guard preset.scope == state.accountScope, state.canChangeAccount else { return .none }
        state.description = preset.description
        state.projectId = state.availableProjects.contains { $0.id == preset.projectId } ? preset.projectId : ""
        return startTimer(&state, stoppingActiveEntry: true)
    }

    private func togglePreset(_ entry: TimeEntry, state: inout State) -> Effect<Action> {
        guard !state.accountScope.isEmpty,
              entry.userId == state.user?.id,
              entry.organizationId == state.data.membership?.organization.id else { return .none }
        let scope = state.accountScope
        let description = entry.description ?? ""
        let projectId = entry.projectId ?? ""
        if let index = state.preferences.workspace.presets.firstIndex(where: {
            $0.scope == scope && $0.description == description && $0.projectId == projectId
        }) {
            state.preferences.workspace.presets.remove(at: index)
        } else {
            state.preferences.workspace.presets.append(TimerPreset(
                id: uuid(),
                scope: scope,
                description: description,
                projectId: projectId
            ))
        }
        return persistWorkspace(state)
    }

    func persistWorkspace(_ state: State) -> Effect<Action> {
        let value = state.preferences.workspace
        return .run { [preferences] _ in preferences.setWorkspace(value) }
    }
}
