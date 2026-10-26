import Charts
import SwiftUI

struct ProjectWorkChart: View {
    let rows: [Row]
    @State private var hoveredProjectID: String?

    struct Row: Identifiable {
        let id: String
        let name: String
        let color: Color
        let seconds: TimeInterval
    }

    var body: some View {
        let rowsByID = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        Chart(rows) { row in
            BarMark(
                x: .value(String(localized: .analyticsHours), row.seconds / 3600),
                y: .value(String(localized: .project), row.id)
            )
            .foregroundStyle(row.color)
            .accessibilityLabel(row.name)
            .accessibilityValue(TrackedTime.clock(row.seconds))
            .annotation(
                position: .trailing,
                spacing: 8,
                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
            ) {
                if hoveredProjectID == row.id {
                    ChartDurationTooltip(duration: row.seconds) { Text(verbatim: row.name) }
                }
            }
        }
        .chartYSelection(value: $hoveredProjectID)
        .onHover {
            if !$0 {
                hoveredProjectID = nil
            }
        }
        .chartYAxis {
            AxisMarks(values: rows.map(\.id)) { value in
                AxisValueLabel {
                    if let id = value.as(String.self), let row = rowsByID[id] {
                        Text(verbatim: row.name)
                    }
                }
            }
        }
        .chartXAxisLabel(String(localized: .analyticsHours))
    }
}
