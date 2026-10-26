import SwiftUI

struct LunchSettingsSection: View {
    @Binding var window: LunchWindow
    let calendar: Calendar

    private var day: Date {
        calendar.date(from: DateComponents(year: 2001, month: 1, day: 15)) ?? .distantPast
    }

    var body: some View {
        Section(.lunchTitle) {
            DatePicker(.lunchStart, selection: time(\.startMinute),
                       in: date(0) ... date(window.endMinute - 1), displayedComponents: .hourAndMinute)
            DatePicker(.lunchEnd, selection: time(\.endMinute),
                       in: date(window.startMinute + 1) ... date(1439), displayedComponents: .hourAndMinute)
            Text(.lunchHelp).font(.callout).foregroundStyle(.secondary)
        }
        .environment(\.calendar, calendar)
        .environment(\.timeZone, calendar.timeZone)
    }

    private func date(_ minute: Int) -> Date {
        calendar.date(byAdding: .minute, value: minute, to: day) ?? day
    }

    private func time(_ keyPath: WritableKeyPath<LunchWindow, Int>) -> Binding<Date> {
        Binding(get: { date(window[keyPath: keyPath]) }, set: { value in
            let components = calendar.dateComponents([.hour, .minute], from: value)
            window[keyPath: keyPath] = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        })
    }
}
