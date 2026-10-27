import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct TimerTrackerView: View {
    let store: StoreOf<AppFeature>
    var style = Style.window
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Style { case window, panel }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let active = store.active {
                    RunningTrackerView(store: store, entry: active, style: style)
                        .transition(stateTransition)
                } else {
                    ReadyTrackerView(store: store, style: style)
                        .transition(stateTransition)
                }
            }
            .frame(minHeight: style == .panel ? 0 : 80, alignment: .center)
            .disabled(store.isBusy || store.destination != nil)
            if style == .window, !store.pinnedPresets.isEmpty {
                PinnedTasksView(store: store)
            }
            if style == .panel, let reminder = store.reminder {
                VStack(alignment: .leading, spacing: 8) {
                    Text(reminder.message).font(.callout).foregroundStyle(.secondary)
                    Button(.reminderDismiss) { send(.dismissReminder) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.9),
                   value: store.active != nil)
    }

    private var stateTransition: AnyTransition {
        reduceMotion ? .identity : .opacity.combined(with: .offset(y: 4))
    }
}

struct TrackerElapsedTime: View {
    let entry: TimeEntry
    var isCompact = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let value = TrackedTime.clock(entry.elapsed(at: context.date))
            Text(value)
                .font(.system(isCompact ? .headline : .largeTitle, design: .rounded).weight(.medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: isCompact, vertical: false)
                .accessibilityLabel(.elapsedTime(value))
        }
        .transaction { $0.animation = nil }
    }
}

struct TrackerStatus: View {
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(isRunning ? Color.green : Color.secondary).frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(isRunning ? .timerRunning : .newTimer)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}
