import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct AnalysisPeriodPicker: View {
    @Bindable var store: StoreOf<WorkspaceFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(.analyticsPeriod)
                Picker(.analyticsPeriod, selection: $store.analysisPeriod) {
                    ForEach(AnalysisPeriod.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                .accessibilityLabel(.analyticsPeriod)
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if store.analysisPeriod == .custom {
                AdaptiveControlRow {
                    DatePicker(
                        .analyticsFrom,
                        selection: $store.customStart,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    DatePicker(
                        .analyticsThrough,
                        selection: $store.customEnd,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                }
            }
        }
    }
}
