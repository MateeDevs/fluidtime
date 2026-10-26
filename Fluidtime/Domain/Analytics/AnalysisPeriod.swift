import Foundation

enum AnalysisPeriod: String, CaseIterable, Equatable, Sendable {
    case week, month, lastMonth, last30Days, last90Days, year, custom

    var title: LocalizedStringResource {
        switch self {
        case .week: .thisWeek
        case .month: .analyticsThisMonth
        case .lastMonth: .analyticsLastMonth
        case .last30Days: .analyticsLast30Days
        case .last90Days: .analyticsLast90Days
        case .year: .analyticsThisYear
        case .custom: .analyticsCustomDates
        }
    }

    func interval(calendar: Calendar, now: Date, start: Date, end: Date) -> DateInterval {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        switch self {
        case .week: return calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: today, end: tomorrow)
        case .month: return calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: today, end: tomorrow)
        case .year: return calendar.dateInterval(of: .year, for: now) ?? DateInterval(start: today, end: tomorrow)
        case .lastMonth:
            let previous = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return calendar.dateInterval(of: .month, for: previous) ?? DateInterval(start: today, end: tomorrow)
        case .last30Days, .last90Days:
            let count = self == .last30Days ? 29 : 89
            return DateInterval(start: calendar.date(byAdding: .day, value: -count, to: today) ?? today, end: tomorrow)
        case .custom:
            let lower = calendar.startOfDay(for: min(start, end))
            let upper = calendar.startOfDay(for: max(start, end))
            return DateInterval(start: lower, end: calendar.date(byAdding: .day, value: 1, to: upper) ?? upper)
        }
    }
}

enum AverageDayBasis: String, CaseIterable, Equatable, Sendable {
    case trackedDays, weekdays, calendarDays

    var title: LocalizedStringResource {
        switch self {
        case .trackedDays: .analyticsTrackedDays
        case .weekdays: .analyticsWeekdays
        case .calendarDays: .analyticsCalendarDays
        }
    }
}
