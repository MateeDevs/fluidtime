import SwiftUI

struct DailyAnalysisTable: View {
    let days: [WorkDay]

    var body: some View {
        List(days.reversed()) { day in
            DailyAnalysisRow(day: day)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .accessibilityLabel(.analyticsDailyDetails)
    }
}
