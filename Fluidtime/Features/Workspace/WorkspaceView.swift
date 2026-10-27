import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct WorkspaceView<Header: View>: View {
    @Bindable var store: StoreOf<WorkspaceFeature>
    let earnings: StoreOf<EarningsFeature>
    let data: SessionData
    let preferences: WorkspacePreferences
    let scope: String
    let isBusy: Bool
    let availableWidth: CGFloat
    @ViewBuilder let header: Header

    var body: some View {
        NavigationSplitView(columnVisibility: columnVisibility) {
            if fitsSidebar {
                sidebar
            } else {
                sidebar.toolbar(removing: .sidebarToggle)
            }
        } detail: {
            VStack(spacing: 0) {
                header.fixedSize(horizontal: false, vertical: true)
                page(store.tab ?? .overview)
                    .id(scope)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(Text((store.tab ?? .overview).title))
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        .toolbar {
            if !fitsSidebar {
                ToolbarItem(placement: .navigation) {
                    Menu {
                        Picker(selection: $store.tab) {
                            ForEach(WorkspaceFeature.Tab.allCases) { tab in
                                Label(tab.title, systemImage: tab.symbol).tag(Optional(tab))
                            }
                        } label: {
                            Text((store.tab ?? .overview).title)
                        }
                    } label: {
                        Label((store.tab ?? .overview).title, systemImage: "sidebar.left")
                    }
                }
            }
        }
        .task(id: scope + (data.user?.timezone ?? "") + (data.user?.weekStart ?? "")) {
            await send(.appeared(scope, data.user?.calendar ?? .current)).finish()
        }
    }

    private var sidebar: some View {
        List(selection: $store.tab) {
            ForEach(WorkspaceFeature.Tab.allCases) { tab in
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.symbol)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(Text(.fluidtime))
        .navigationSplitViewColumnWidth(min: 170, ideal: 210, max: 280)
    }

    private var fitsSidebar: Bool {
        availableWidth >= 760
    }

    private var columnVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { fitsSidebar ? store.columnVisibility : .detailOnly },
            set: {
                if fitsSidebar {
                    store.columnVisibility = $0
                }
            }
        )
    }

    @ViewBuilder
    private func page(_ tab: WorkspaceFeature.Tab) -> some View {
        if tab == .history {
            EntryHistoryView(store: store, data: data, preferences: preferences, isBusy: isBusy)
        } else {
            AnalyticsView(store: store, earnings: earnings, data: data, preferences: preferences, tab: tab)
        }
    }
}
