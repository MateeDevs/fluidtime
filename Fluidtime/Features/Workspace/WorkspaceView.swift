import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct WorkspaceView<Header: View, Footer: View>: View {
    @Bindable var store: StoreOf<WorkspaceFeature>
    let earnings: StoreOf<EarningsFeature>
    let data: SessionData
    let preferences: WorkspacePreferences
    let scope: String
    let isBusy: Bool
    let isCompact: Bool
    @ViewBuilder let header: Header
    @ViewBuilder let footer: Footer

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header.fixedSize(horizontal: false, vertical: true)
                ZStack {
                    ForEach(WorkspaceFeature.Tab.allCases) { tab in
                        page(tab)
                            .opacity((store.tab ?? .overview) == tab ? 1 : 0)
                            .allowsHitTesting((store.tab ?? .overview) == tab)
                            .accessibilityHidden((store.tab ?? .overview) != tab)
                            .disabled((store.tab ?? .overview) != tab)
                    }
                }
                .id(scope)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                footer.fixedSize(horizontal: false, vertical: true)
            }
            .navigationTitle(isCompact ? Text(verbatim: "") : Text(.fluidtime))
        }
        .task(id: scope + (data.user?.timezone ?? "") + (data.user?.weekStart ?? "")) {
            await send(.appeared(scope, data.user?.calendar ?? .current)).finish()
        }
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
