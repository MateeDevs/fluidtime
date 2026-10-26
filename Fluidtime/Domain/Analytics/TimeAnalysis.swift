import Foundation

struct TimeAnalysis: Equatable, Sendable {
    let days: [WorkDay]
    let calendar: Calendar

    init(
        entries: [TimeEntry], calendar: Calendar, interval: DateInterval, now: Date,
        lunchWindow: LunchWindow = LunchWindow()
    ) {
        self.calendar = calendar
        let end = min(interval.end, now)
        guard interval.start < end else { days = []; return }
        var grouped: [Date: [Segment]] = [:]
        let unique = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        for entry in unique.values {
            var cursor = max(entry.start, interval.start)
            let last = min(entry.end ?? now, end)
            while cursor < last, let day = calendar.dateInterval(of: .day, for: cursor) {
                let segment = DateInterval(start: cursor, end: min(last, day.end))
                grouped[day.start, default: []].append(Segment(interval: segment, entry: entry))
                cursor = segment.end
            }
        }
        var result: [WorkDay] = []
        var day = calendar.startOfDay(for: interval.start)
        while day < end {
            result.append(Self.makeDay(day, segments: grouped[day] ?? [], calendar: calendar, lunchWindow: lunchWindow))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day), next > day else { break }
            day = next
        }
        days = result
    }

    var work: TimeInterval {
        days.reduce(0) { $0 + $1.work }
    }

    var lunch: TimeInterval {
        days.reduce(0) { $0 + $1.lunch }
    }

    var timeAtWork: TimeInterval {
        days.reduce(0) { $0 + $1.timeAtWork }
    }

    var gaps: TimeInterval {
        days.reduce(0) { $0 + $1.gaps }
    }

    func averages(basis: AverageDayBasis, calendar: Calendar) -> Averages {
        let eligible = days.filter { day in
            switch basis {
            case .trackedDays: day.timeAtWork > 0
            case .weekdays: !calendar.isDateInWeekend(day.date)
            case .calendarDays: true
            }
        }
        let count = Double(max(1, eligible.count))
        let weeks = Set(days.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start }).count
        let months = Set(days.compactMap { calendar.dateInterval(of: .month, for: $0.date)?.start }).count
        return Averages(
            day: eligible.reduce(0) { $0 + $1.work } / count,
            lunchTime: eligible.reduce(0) { $0 + $1.lunch } / count,
            week: work / Double(max(1, weeks)), month: work / Double(max(1, months)), dayCount: eligible.count
        )
    }

    var projectTotals: [String: TimeInterval] {
        days.reduce(into: [:]) { totals, day in
            for (id, seconds) in day.projects {
                totals[id, default: 0] += seconds
            }
        }
    }

    private static func makeDay(
        _ date: Date, segments: [Segment], calendar: Calendar, lunchWindow: LunchWindow
    ) -> WorkDay {
        var day = WorkDay(date: date)
        let work = segments.sorted {
            ($0.interval.start, $0.entry.id) < ($1.interval.start, $1.entry.id)
        }
        day.firstStart = work.map(\.interval.start).min()
        day.lastEnd = work.map(\.interval.end).max()
        day.lunchInterval = lunchWindow.longestGap(in: work.map(\.interval), calendar: calendar)
        day.workIntervals = TimeIntervals.merged(work.map(\.interval))
        day.billableIntervals = TimeIntervals.merged(work.filter(\.entry.billable).map(\.interval))
        var assigned: [DateInterval] = []
        for segment in work {
            let available = TimeIntervals.subtracting(assigned, from: [segment.interval])
            day.projects[segment.entry.projectId ?? "", default: 0] += TimeIntervals.duration(available)
            assigned = TimeIntervals.merged(assigned + available)
        }
        return day
    }

    struct Averages: Equatable, Sendable {
        let day: TimeInterval
        let lunchTime: TimeInterval
        let week: TimeInterval
        let month: TimeInterval
        let dayCount: Int
    }

    private struct Segment {
        let interval: DateInterval
        let entry: TimeEntry
    }
}
