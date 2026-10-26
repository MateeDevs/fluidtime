import Charts
import SwiftUI

struct DailyWorkChart: View {
    let days: [WorkDay]
    let calendar: Calendar
    @State private var hoveredDate: Date?

    var body: some View {
        Chart(days) { day in
            BarMark(
                x: .value(String(localized: .analyticsDay), day.date, unit: .day),
                y: .value(String(localized: .analyticsHours), day.work / 3600)
            )
            .accessibilityLabel(Text(day.date, style: .date))
            .accessibilityValue(TrackedTime.clock(day.work))
            .annotation(
                position: .top,
                spacing: 8,
                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
            ) {
                if hoveredDate == day.date {
                    ChartDurationTooltip(duration: day.work) {
                        Text(day.date, format: .dateTime.weekday(.wide).day().month(.abbreviated).year())
                    }
                }
            }
        }
        .chartXSelection(value: Binding(get: { hoveredDate }, set: selectDate))
        .onHover {
            if !$0 {
                selectDate(nil)
            }
        }
        .chartYAxisLabel(String(localized: .analyticsHours))
        .environment(\.calendar, calendar)
        .environment(\.timeZone, calendar.timeZone)
    }

    private func selectDate(_ date: Date?) {
        let day = date.map { calendar.startOfDay(for: $0) }
        if hoveredDate != day {
            hoveredDate = day
        }
    }
}
