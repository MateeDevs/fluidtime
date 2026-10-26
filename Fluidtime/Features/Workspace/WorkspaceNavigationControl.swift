import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct WorkspaceNavigationControl: View {
    @Bindable var store: StoreOf<WorkspaceFeature>
    let isCompact: Bool

    var body: some View {
        Group {
            if isCompact {
                Menu {
                    ForEach(WorkspaceFeature.Tab.allCases) { tab in
                        Button { send(.binding(.set(\.tab, tab))) } label: {
                            if (store.tab ?? .overview) == tab {
                                Label(tab.title, systemImage: "checkmark")
                            } else {
                                Text(tab.title)
                            }
                        }
                        .accessibilityAddTraits((store.tab ?? .overview) == tab ? .isSelected : [])
                    }
                } label: {
                    Text((store.tab ?? .overview).title).lineLimit(1)
                }
                .frame(maxWidth: 160)
            } else {
                Picker(.workspaceNavigation, selection: Binding(
                    get: { store.tab ?? .overview },
                    set: { send(.binding(.set(\.tab, $0))) }
                )) {
                    ForEach(WorkspaceFeature.Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .accessibilityLabel(.workspaceNavigation)
    }
}
