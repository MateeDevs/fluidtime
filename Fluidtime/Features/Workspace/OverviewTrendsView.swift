import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct OverviewTrendsView: View {
    @Bindable var store: StoreOf<WorkspaceFeature>
    let data: SessionData
    let preferences: WorkspacePreferences
    let analysis: TimeAnalysis
    let now: Date

    var body: some View {
        let averages = analysis.averages(basis: store.averageBasis, calendar: store.calendar)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        AdaptiveControlRow {
                            Text(.analyticsAverageOver)
                            Picker(.analyticsAverageOver, selection: $store.averageBasis) {
                                ForEach(AverageDayBasis.allCases, id: \.self) { Text($0.title).tag($0) }
                            }
                            .labelsHidden()
                            .accessibilityLabel(.analyticsAverageOver)
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        MetricGrid {
                            metric(.analyticsAverageDay, averages.day)
                            metric(.analyticsAverageWeek, averages.week)
                            metric(.analyticsAverageMonth, averages.month)
                            metric(.analyticsAverageLunch, averages.lunchTime)
                        }
                    }.padding(6)
                } label: { InfoLabel(title: .analyticsAverages, explanation: .analyticsAverageHelp) }
                comparison
                AnalyticsCharts(analysis: analysis, projects: data.projects)
            }.padding(16)
        }
    }

    private var comparison: some View {
        let previous = store.state.previousAnalysis(data, at: now, lunchWindow: preferences.lunchWindow)
        return HStack {
            MetricView(title: store.analysisPeriod == .month ? .analyticsPreviousMonthToDate : .analyticsPreviousWork,
                       value: TrackedTime.clock(previous.work), explanation: .analyticsComparisonHelp)
            MetricView(title: .analyticsChange, value: previous.work > 0
                ? (analysis.work / previous.work - 1).formatted(.percent.precision(.fractionLength(0)))
                : String(localized: .durationUnavailable))
        }
    }

    private func metric(_ title: LocalizedStringResource, _ seconds: TimeInterval) -> some View {
        MetricView(title: title, value: TrackedTime.clock(seconds))
    }
}
