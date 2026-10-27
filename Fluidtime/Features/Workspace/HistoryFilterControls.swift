import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct HistoryFilterControls: View {
    @Bindable var store: StoreOf<WorkspaceFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let projects: [Project]
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(String(localized: .historySearch), text: $store.history.search).textFieldStyle(.roundedBorder)
                .accessibilityLabel(.historySearch)
                .focused($isSearchFocused)
                .task(id: store.searchFocusRequest) {
                    if store.searchFocusRequest > 0 {
                        isSearchFocused = true
                    }
                }
            AdaptiveControlRow {
                VStack(alignment: .leading, spacing: 4) {
                    Text(.project).font(.caption).foregroundStyle(.secondary)
                    ProjectPicker(projects: projects, selected: $store.history.projectId,
                                  allowsAllProjects: true, showsLabel: false)
                        .frame(maxWidth: 240)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(.analyticsPeriod).font(.caption).foregroundStyle(.secondary)
                    Picker(.analyticsPeriod, selection: $store.history.period) {
                        ForEach(AnalysisPeriod.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .accessibilityLabel(.analyticsPeriod)
                    .fixedSize(horizontal: true, vertical: false)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(.historyBillability).font(.caption).foregroundStyle(.secondary)
                    Picker(.historyBillability, selection: $store.history.billability) {
                        ForEach(HistoryFilter.Billability.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .accessibilityLabel(.historyBillability)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            if store.history.period == .custom {
                AdaptiveControlRow {
                    DatePicker(
                        .analyticsFrom,
                        selection: $store.history.start,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    DatePicker(
                        .analyticsThrough,
                        selection: $store.history.end,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                }
                .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: store.history.period == .custom)
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .controlSize(.small)
    }
}
