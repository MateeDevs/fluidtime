import ComposableArchitecture
import Foundation

extension WorkspaceFeature {
    @ObservableState
    struct State: Equatable {
        var tab: Tab? = .overview
        var searchFocusRequest = 0
        var history = HistoryFilter()
        var historyPresentation: HistoryPresentation?
        var historyRequestID: UUID?
        var analysisPeriod = AnalysisPeriod.month
        var customStart = Date.distantPast
        var customEnd = Date.distantPast
        var averageBasis = AverageDayBasis.trackedDays
        var calendar = Calendar.current
        var accountScope = ""
        var billableOnly = false
        var exportError: String?

        func interval(at now: Date) -> DateInterval {
            analysisPeriod.interval(calendar: calendar, now: now, start: customStart, end: customEnd)
        }

        func analysis(_ data: SessionData, at now: Date, lunchWindow: LunchWindow = LunchWindow()) -> TimeAnalysis {
            TimeAnalysis(entries: data.entries, calendar: calendar, interval: interval(at: now), now: now,
                         lunchWindow: lunchWindow)
        }

        func previousAnalysis(
            _ data: SessionData, at now: Date, lunchWindow: LunchWindow = LunchWindow()
        ) -> TimeAnalysis {
            let current = interval(at: now)
            let component: Calendar.Component = switch analysisPeriod {
            case .week: .weekOfYear
            case .month, .lastMonth: .month
            case .year: .year
            default: .day
            }
            let days = max(1, calendar.dateComponents([.day], from: current.start, to: current.end).day ?? 1)
            let start = calendar.date(byAdding: component, value: component == .day ? -days : -1, to: current.start)
                ?? current.start
            let elapsed = max(0, min(now, current.end).timeIntervalSince(current.start))
            let end = min(current.start, start.addingTimeInterval(elapsed))
            return TimeAnalysis(
                entries: data.entries,
                calendar: calendar,
                interval: DateInterval(start: start, end: end),
                now: now,
                lunchWindow: lunchWindow
            )
        }
    }

    enum Tab: String, CaseIterable, Identifiable {
        case overview, history, analysis, daily
        var id: Self {
            self
        }

        var title: LocalizedStringResource {
            switch self {
            case .overview: .workspaceOverview
            case .history: .workspaceHistory
            case .analysis: .overviewCharts
            case .daily: .analyticsDailyDetails
            }
        }

        var shortcut: Character {
            switch self {
            case .overview: "1"
            case .history: "2"
            case .analysis: "3"
            case .daily: "4"
            }
        }

        var symbol: String {
            switch self {
            case .overview: "chart.bar"
            case .history: "list.bullet.rectangle"
            case .analysis: "chart.xyaxis.line"
            case .daily: "calendar"
            }
        }
    }
}
