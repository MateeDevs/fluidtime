import Foundation

enum TrackedTime {
    static func total(_ entries: [TimeEntry], in interval: DateInterval, now: Date) -> TimeInterval {
        let segments = entries.compactMap { entry -> DateInterval? in
            let start = max(entry.start, interval.start)
            let end = min(entry.end ?? now, min(now, interval.end))
            guard start < end else { return nil }
            return DateInterval(start: start, end: end)
        }
        return TimeIntervals.duration(TimeIntervals.merged(segments))
    }

    static func clock(_ seconds: TimeInterval, showsSeconds: Bool = true) -> String {
        let value = Int(max(0, seconds))
        guard showsSeconds else { return String(format: "%d:%02d", value / 3600, value / 60 % 60) }
        return String(format: "%d:%02d:%02d", value / 3600, value / 60 % 60, value % 60)
    }
}
