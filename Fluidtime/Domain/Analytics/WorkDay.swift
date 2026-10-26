import Foundation

struct WorkDay: Identifiable, Equatable, Sendable {
    var id: Date {
        date
    }

    let date: Date
    var workIntervals: [DateInterval] = []
    var billableIntervals: [DateInterval] = []
    var lunchInterval: DateInterval?
    var firstStart: Date?
    var lastEnd: Date?
    var projects: [String: TimeInterval] = [:]

    var work: TimeInterval {
        TimeIntervals.duration(workIntervals)
    }

    var lunch: TimeInterval {
        lunchInterval?.duration ?? 0
    }

    var billable: TimeInterval {
        TimeIntervals.duration(billableIntervals)
    }

    var timeAtWork: TimeInterval {
        guard let firstStart, let lastEnd else { return 0 }
        return max(0, lastEnd.timeIntervalSince(firstStart))
    }

    var gaps: TimeInterval {
        max(0, timeAtWork - work - lunch)
    }
}
