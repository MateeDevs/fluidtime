import Foundation

struct LunchWindow: Codable, Equatable, Sendable {
    var startMinute = 11 * 60
    var endMinute = 15 * 60

    var normalized: Self {
        let start = min(max(0, startMinute), 1438)
        return Self(startMinute: start, endMinute: min(max(start + 1, endMinute), 1439))
    }

    func longestGap(in intervals: [DateInterval], calendar: Calendar) -> DateInterval? {
        let work = TimeIntervals.merged(intervals)
        let window = normalized
        return zip(work, work.dropFirst()).compactMap { previous, next -> DateInterval? in
            guard previous.end < next.start,
                  calendar.isDate(previous.end, inSameDayAs: next.start) else { return nil }
            let gap = DateInterval(start: previous.end, end: next.start)
            let midpoint = gap.start.addingTimeInterval(gap.duration / 2)
            let time = calendar.dateComponents([.hour, .minute, .second], from: midpoint)
            let second = (time.hour ?? 0) * 3600 + (time.minute ?? 0) * 60 + (time.second ?? 0)
            return second >= window.startMinute * 60 && second < window.endMinute * 60 ? gap : nil
        }.max { first, second in
            first.duration == second.duration ? first.start > second.start : first.duration < second.duration
        }
    }
}
