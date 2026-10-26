import SwiftUI

struct DailyAnalysisRow: View {
    let day: WorkDay

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.date, format: .dateTime.weekday(.wide)).font(.headline)
                    Text(day.date, format: .dateTime.day().month(.wide).year())
                        .font(.callout).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(.analyticsWorkTime)
                        .font(.caption).foregroundStyle(.secondary)
                    Text(TrackedTime.clock(day.work, showsSeconds: false))
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityElement(children: .combine)
            }
            if day.firstStart != nil {
                VStack(spacing: 8) {
                    DailyWorkTimeline(day: day)
                    HStack {
                        boundary(.analyticsFirstStart, day.firstStart)
                        Spacer()
                        boundary(.analyticsLastEnd, day.lastEnd)
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) { metrics }
                        .frame(minWidth: 520)
                    VStack(alignment: .leading, spacing: 12) { metrics }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var metrics: some View {
        metric(.analyticsTimeAtWork, day.timeAtWork, symbol: "clock", color: .secondary)
        metric(.analyticsLunchTime, day.lunch, symbol: "fork.knife", color: .orange)
        metric(.analyticsUntrackedGaps, day.gaps, symbol: "ellipsis", color: .secondary)
    }

    private func metric(
        _ title: LocalizedStringResource,
        _ duration: TimeInterval,
        symbol: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: symbol).foregroundStyle(color).accessibilityHidden(true)
                Text(title).foregroundStyle(.secondary)
            }
            .font(.caption)
            Text(TrackedTime.clock(duration, showsSeconds: false))
                .font(.callout.monospacedDigit()).fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func boundary(_ title: LocalizedStringResource, _ date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).foregroundStyle(.secondary)
            if let date {
                Text(date, style: .time).monospacedDigit()
            } else {
                Text(.durationUnavailable)
            }
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }
}
