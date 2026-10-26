import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct AnalyticsView: View {
    @Bindable var store: StoreOf<WorkspaceFeature>
    let earnings: StoreOf<EarningsFeature>
    let data: SessionData
    let preferences: WorkspacePreferences
    let tab: WorkspaceFeature.Tab

    var body: some View {
        TimelineView(.periodic(from: (store.tab ?? .overview) == tab ? .now : .distantFuture, by: 1)) { context in
            let date = (store.tab ?? .overview) == tab ? context.date : Date.now
            let analysis = store.state.analysis(data, at: date, lunchWindow: preferences.lunchWindow)
            VStack(alignment: .leading, spacing: 12) {
                AnalysisPeriodPicker(store: store)
                    .padding(.horizontal, 16)
                if data.lastSynced == nil {
                    Text(.analyticsUnavailable).foregroundStyle(.secondary).padding(.horizontal, 16)
                }
                Group {
                    switch tab {
                    case .overview:
                        OverviewSummaryView(store: store, earnings: earnings, data: data,
                                            preferences: preferences, analysis: analysis, now: date)
                    case .analysis:
                        OverviewTrendsView(store: store, data: data, preferences: preferences,
                                           analysis: analysis, now: date)
                    case .daily:
                        DailyAnalysisTable(days: analysis.days)
                            .environment(\.timeZone, store.calendar.timeZone)
                    case .history:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let error = store.exportError {
                    Text(error).font(.callout).foregroundStyle(.secondary).padding(.horizontal, 16)
                }
            }
            .padding(.top, 16)
        }
    }
}
