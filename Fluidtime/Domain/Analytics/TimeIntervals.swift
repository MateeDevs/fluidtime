import Foundation

enum TimeIntervals {
    static func merged(_ values: [DateInterval]) -> [DateInterval] {
        var result: [DateInterval] = []
        for value in values.filter({ $0.duration > 0 }).sorted(by: { $0.start < $1.start }) {
            if let previous = result.last, value.start <= previous.end {
                result[result.count - 1] = DateInterval(start: previous.start, end: max(previous.end, value.end))
            } else {
                result.append(value)
            }
        }
        return result
    }

    static func subtracting(_ excluded: [DateInterval], from intervals: [DateInterval]) -> [DateInterval] {
        let excluded = merged(excluded)
        return merged(intervals).flatMap { interval in
            var cursor = interval.start
            var result: [DateInterval] = []
            for cut in excluded where cut.end > cursor && cut.start < interval.end {
                if cut.start > cursor {
                    result.append(DateInterval(start: cursor, end: min(cut.start, interval.end)))
                }
                cursor = max(cursor, cut.end)
                if cursor >= interval.end {
                    break
                }
            }
            if cursor < interval.end {
                result.append(DateInterval(start: cursor, end: interval.end))
            }
            return result
        }
    }

    static func duration(_ intervals: [DateInterval]) -> TimeInterval {
        intervals.reduce(0) { $0 + $1.duration }
    }
}
