import SwiftUI

struct AnalyticsCharts: View {
    let analysis: TimeAnalysis
    let projects: [Project]

    var body: some View {
        VStack(spacing: 20) {
            GroupBox {
                DailyWorkChart(days: analysis.days, calendar: analysis.calendar)
                    .frame(height: 210).padding(8)
            } label: { Text(.analyticsDailyWork) }

            GroupBox {
                let rows = projectRows
                if rows.isEmpty {
                    Text(.analyticsNoWork).foregroundStyle(.secondary).padding()
                } else {
                    ProjectWorkChart(rows: rows)
                        .frame(height: CGFloat(max(180, rows.count * 32))).padding(8)
                }
            } label: { Text(.analyticsByProject) }
        }
    }

    private var projectRows: [ProjectWorkChart.Row] {
        let projectsByID = Dictionary(projects.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return analysis.projectTotals.filter { $0.value > 0 }.sorted { $0.value > $1.value }.map { id, seconds in
            let project = projectsByID[id]
            return ProjectWorkChart.Row(
                id: id,
                name: project?.name ?? String(localized: id.isEmpty ? .noProject : .unavailableProject),
                color: Color(projectHex: project?.color),
                seconds: seconds
            )
        }
    }
}
