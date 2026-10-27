import ComposableArchitecture
import SwiftUI

struct MainTimerControls: View {
    let store: StoreOf<AppFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: store.workspace.isTimerCollapsed ? .center : .top, spacing: 8) {
            Group {
                if store.workspace.isTimerCollapsed {
                    CompactMainTimer(store: store)
                        .transition(reduceMotion ? .identity : .opacity)
                } else {
                    expandedTimer
                        .transition(reduceMotion ? .identity : .opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            MainTimerDisclosure(store: store.scope(state: \.workspace, action: \.workspace))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, store.workspace.isTimerCollapsed ? 8 : 12)
    }

    private var expandedTimer: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimerTrackerView(store: store)
            if store.active == nil {
                Divider()
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let totals = store.data.totals(at: context.date)
                let month = store.data.total(in: .month, at: context.date)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) {
                        total(.today, value: totals.today)
                        total(.thisWeek, value: totals.week)
                        total(.analyticsThisMonth, value: month)
                    }.fixedSize(horizontal: store.active != nil, vertical: false)
                    VStack(alignment: .leading, spacing: 8) {
                        total(.today, value: totals.today)
                        total(.thisWeek, value: totals.week)
                        total(.analyticsThisMonth, value: month)
                    }
                }
            }
        }
    }

    private func total(_ title: LocalizedStringResource, value: TimeInterval) -> some View {
        Group {
            if store.active != nil {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title).font(.callout).foregroundStyle(.secondary)
                    duration(value)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    duration(value).fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func duration(_ value: TimeInterval) -> some View {
        Text(store.lastSynced == nil ? String(localized: .durationUnavailable) : TrackedTime.clock(value))
            .font(.headline.monospacedDigit())
    }
}
