import SwiftUI

struct WorkFinishCaption: View {
    let data: SessionData
    let targetHours: Double
    let tracked: TimeInterval
    let now: Date
    @Environment(\.locale) private var locale

    var body: some View {
        let finish = WorkFinish.calculate(targetHours: targetHours, tracked: tracked, now: now)
        if data.lastSynced != nil, let calendar = data.user?.calendar, let finish {
            Text(message(finish, calendar: calendar))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .help(.finishHelp)
        }
    }

    private func message(_ finish: WorkFinish, calendar: Calendar) -> LocalizedStringResource {
        guard case let .expected(date) = finish else { return .finishTargetReached }
        let time = date.formatted(Date.FormatStyle(
            date: .omitted, time: .shortened, locale: locale,
            calendar: calendar, timeZone: calendar.timeZone
        ))
        let running = data.active != nil && !data.activeInAnotherOrganization
        if calendar.isDate(date, inSameDayAs: now) {
            return running ? .finishExpectedAt(time) : .finishStartNowAt(time)
        }
        return running ? .finishExpectedTomorrowAt(time) : .finishStartNowTomorrowAt(time)
    }
}
