import Foundation

extension WorkspaceFeature.State {
    func exportDocument(data: SessionData, at now: Date, lunchWindow: LunchWindow) -> CSVDocument {
        if tab == .history {
            return .entries(history.entries(data.entries, calendar: calendar, now: now),
                            projects: data.projects, now: now)
        }
        return .summary(analysis(data, at: now, lunchWindow: lunchWindow), calendar: calendar)
    }
}
