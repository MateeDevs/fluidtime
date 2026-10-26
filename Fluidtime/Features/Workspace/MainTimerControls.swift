import ComposableArchitecture
import SwiftUI

struct MainTimerControls: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimerTrackerView(store: store)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let totals = store.data.totals(at: context.date)
                let month = store.data.total(in: .month, at: context.date)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) {
                        total(.today, value: totals.today)
                        total(.thisWeek, value: totals.week)
                        total(.analyticsThisMonth, value: month)
                    }.fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: 8) {
                        total(.today, value: totals.today)
                        total(.thisWeek, value: totals.week)
                        total(.analyticsThisMonth, value: month)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func total(_ title: LocalizedStringResource, value: TimeInterval) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title).font(.callout).foregroundStyle(.secondary)
            Text(TrackedTime.clock(value)).font(.headline.monospacedDigit())
        }
        .accessibilityElement(children: .combine)
    }
}
