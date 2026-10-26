import Foundation

struct HistoryFilter: Equatable, Sendable {
    var search = ""
    var projectId = "all"
    var billability = Billability.all
    var period = AnalysisPeriod.month
    var start = Date.distantPast
    var end = Date.distantPast

    func entries(_ entries: [TimeEntry], calendar: Calendar, now: Date) -> [TimeEntry] {
        let interval = period.interval(calendar: calendar, now: now, start: start, end: end)
        return entries.filter { entry in
            entry.start <= now && entry.start < interval
                .end && (entry.end.map { $0 > interval.start } ?? (now >= interval.start))
                && (projectId == "all" || (entry.projectId ?? "") == projectId)
                && (search.isEmpty || (entry.description ?? "").localizedStandardContains(search))
                && (billability == .all || entry.billable == (billability == .billable))
        }.sorted {
            $0.start == $1.start ? $0.id < $1.id : $0.start > $1.start
        }
    }

    enum Billability: String, CaseIterable, Sendable {
        case all, billable, nonBillable

        var title: LocalizedStringResource {
            switch self {
            case .all: .historyAllBillability
            case .billable: .historyBillable
            case .nonBillable: .historyNonBillable
            }
        }
    }
}
