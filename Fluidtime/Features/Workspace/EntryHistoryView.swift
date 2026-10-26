import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct EntryHistoryView: View {
    @Bindable var store: StoreOf<WorkspaceFeature>
    let data: SessionData
    let preferences: WorkspacePreferences
    let isBusy: Bool

    var body: some View {
        let input = HistoryPresentation.Input(scope: store.accountScope, entries: data.entries,
                                              projects: data.projects, presets: preferences.presets,
                                              filter: store.history, calendar: store.calendar,
                                              day: store.calendar.startOfDay(for: .now))
        let sections = store.historyPresentation?.scope == input.scope ? store.historyPresentation?.sections : nil
        VStack(alignment: .leading, spacing: 12) {
            HistoryFilterControls(store: store, projects: data.projects)
                .padding(.horizontal, 8)
            if let error = store.exportError {
                Text(error).font(.callout).foregroundStyle(.secondary).padding(.horizontal, 8)
            }
            if let sections, sections.isEmpty {
                ContentUnavailableView {
                    Label(.historyNoEntries, systemImage: "list.bullet.rectangle")
                } description: { Text(data.lastSynced == nil ? .analyticsUnavailable : .historyAdjustFilters) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sections ?? []) { group in
                        Section {
                            ForEach(group.rows) { row in
                                historyRow(row)
                            }
                        } header: {
                            Text(group.id, format: .dateTime.weekday(.wide).day().month(.wide).year())
                        }
                    }
                }
                .listStyle(.plain)
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
        .padding(.vertical, 20)
        .task(id: input) { await send(.historyInputChanged(input)).finish() }
    }

    private func historyRow(_ row: HistoryPresentation.Row) -> some View {
        EntryHistoryRow(entry: row.entry, project: row.project,
                        isPinned: row.isPinned, hasActiveTimer: data.active != nil,
                        edit: { send(.editTapped(row.entry, anchor: "history.\(row.id)")) },
                        start: { send(.startTapped(row.entry)) },
                        pin: { send(.pinTapped(row.entry)) },
                        delete: { send(.deleteTapped(row.entry)) })
            .disabled(isBusy)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12))
    }
}
