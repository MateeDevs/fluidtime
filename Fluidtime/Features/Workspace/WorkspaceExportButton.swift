import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct WorkspaceExportButton: View {
    let store: StoreOf<WorkspaceFeature>
    let data: SessionData
    let lunchWindow: LunchWindow
    let isBusy: Bool

    private var title: LocalizedStringResource {
        store.tab == .history ? .exportEntries : .exportSummary
    }

    var body: some View {
        Button {
            send(.export(store.state.exportDocument(data: data, at: .now, lunchWindow: lunchWindow)))
        } label: {
            Label(title, systemImage: "square.and.arrow.up")
        }
        .help(title)
        .accessibilityLabel(title)
        .disabled(isBusy || data.lastSynced == nil)
    }
}
