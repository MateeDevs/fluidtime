import Foundation

struct CSVDocument: Equatable, Sendable {
    var filename: String
    var contents: String

    static func cell(_ value: String) -> String {
        var text = value
        let startsFormula = text.drop(while: \.isWhitespace).first.map { "=+-@".contains($0) } ?? false
        let startsControl = text.first.map { "\t\r\n".contains($0) } ?? false
        if startsFormula || startsControl {
            text = "'" + text
        }
        return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func entries(_ entries: [TimeEntry], projects: [Project], now: Date) -> Self {
        var rows = [[
            String(localized: .description), String(localized: .project), String(localized: .exportStartUtc),
            String(localized: .exportEndUtc), String(localized: .exportWorkSeconds),
            String(localized: .historyBillable)
        ]]
        rows += entries.map { entry in
            [
                entry.description ?? "", projects.first { $0.id == entry.projectId }?.name ?? "",
                entry.start.ISO8601Format(), entry.end?.ISO8601Format() ?? "",
                String(Int(entry.elapsed(at: now))),
                String(localized: entry.billable ? .exportYes : .exportNo)
            ]
        }
        return Self(
            filename: String(localized: .exportEntriesFilename),
            contents: rows.map { $0.map(cell).joined(separator: ",") }.joined(separator: "\r\n")
        )
    }

    static func summary(_ analysis: TimeAnalysis, calendar: Calendar) -> Self {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        var rows = [[
            String(localized: .analyticsDay), String(localized: .exportWorkSeconds),
            String(localized: .exportLunchSeconds), String(localized: .exportAtWorkSeconds),
            String(localized: .exportGapSeconds)
        ]]
        rows += analysis.days.map {
            [formatter.string(from: $0.date), String(Int($0.work)), String(Int($0.lunch)),
             String(Int($0.timeAtWork)), String(Int($0.gaps))]
        }
        return Self(
            filename: String(localized: .exportSummaryFilename),
            contents: rows.map { $0.map(cell).joined(separator: ",") }.joined(separator: "\r\n")
        )
    }
}
