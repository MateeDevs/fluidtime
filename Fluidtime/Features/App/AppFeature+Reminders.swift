import ComposableArchitecture
import Foundation

extension AppFeature {
    func checkReminders(_ state: State) -> Effect<Action> {
        let options = state.preferences.workspace
        guard let active = state.active,
              options.idleReminderMinutes > 0 || options.longTimerReminderHours > 0 else { return .none }
        let id = active.id
        return .run { [system] send in
            await send(.reminderInputReceived(id, system.idleSeconds()))
        }
    }

    func handleReminder(entryId: String, idleSeconds: TimeInterval, state: inout State) -> Effect<Action> {
        guard let active = state.active, active.id == entryId else { return .none }
        if state.remindedEntryId != entryId {
            state.remindedEntryId = entryId
            state.remindedKinds = []
            state.reminder = nil
        }
        let options = state.preferences.workspace
        let kind: TimerReminder
        let needsIdleReminder = options.idleReminderMinutes > 0
            && idleSeconds >= Double(options.idleReminderMinutes) * 60
            && !state.remindedKinds.contains(.idle)
        let needsLongReminder = options.longTimerReminderHours > 0
            && active.elapsed(at: now) >= Double(options.longTimerReminderHours) * 3600
            && !state.remindedKinds.contains(.longRunning)
        if needsIdleReminder {
            kind = .idle
        } else if needsLongReminder {
            kind = .longRunning
        } else {
            return .none
        }
        state.reminder = kind
        state.remindedKinds.insert(kind)
        return .run { [system] _ in
            await system.showTimerFeedback(kind == .idle ? .idleReminder : .longRunningReminder)
        }
    }
}
