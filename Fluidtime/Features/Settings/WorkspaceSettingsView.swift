import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct WorkspaceSettingsView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Form {
            Section(.goalsTitle) {
                TextField(String(localized: .goalsDailyHours), value: preference(\.dailyGoalHours), format: .number)
                TextField(String(localized: .goalsWeeklyHours), value: preference(\.weeklyGoalHours), format: .number)
                Text(.goalsHelp).font(.callout).foregroundStyle(.secondary)
            }
            LunchSettingsSection(window: preference(\.lunchWindow), calendar: store.user?.calendar ?? .current)
            Section(.reminderTitle) {
                Toggle(.feedbackShowConfirmations, isOn: preference(\.timerFeedback))
                Stepper(value: preference(\.idleReminderMinutes), in: 0 ... 120, step: 5) {
                    LabeledContent(
                        String(localized: .reminderIdleMinutes),
                        value: store.preferences.workspace.idleReminderMinutes.formatted()
                    )
                }
                Stepper(value: preference(\.longTimerReminderHours), in: 0 ... 24) {
                    LabeledContent(
                        String(localized: .reminderLongHours),
                        value: store.preferences.workspace.longTimerReminderHours.formatted()
                    )
                }
                Text(.reminderHelp).font(.callout).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped)
    }

    private func preference<Value>(_ keyPath: WritableKeyPath<WorkspacePreferences, Value>) -> Binding<Value> {
        Binding(get: { store.preferences.workspace[keyPath: keyPath] }, set: { value in
            var options = store.preferences.workspace
            options[keyPath: keyPath] = value
            send(.workspacePreferencesChanged(options))
        })
    }
}
