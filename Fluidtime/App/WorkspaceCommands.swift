import ComposableArchitecture
import SwiftUI

struct WorkspaceStoreKey: FocusedValueKey {
    typealias Value = StoreOf<AppFeature>
}

extension FocusedValues {
    var workspaceStore: StoreOf<AppFeature>? {
        get { self[WorkspaceStoreKey.self] }
        set { self[WorkspaceStoreKey.self] = newValue }
    }
}

struct WorkspaceCommands: Commands {
    @FocusedValue(\.workspaceStore) private var store

    private var canUseWorkspace: Bool {
        store?.isConnected == true && store?.destination == nil
    }

    private var canExport: Bool {
        canUseWorkspace && store?.isBusy == false && store?.lastSynced != nil
    }

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(store?.workspace.tab == .history ? .exportEntries : .exportSummary) { export() }
                .disabled(!canExport)
            Button(.openSolidtime) { store?.send(.view(.openInstanceTapped)) }
                .disabled(!canUseWorkspace)
        }
        CommandGroup(after: .textEditing) {
            Button(.commandFind) { store?.send(.workspace(.view(.find))) }
                .keyboardShortcut("f")
                .disabled(!canUseWorkspace)
        }
        CommandGroup(after: .toolbar) {
            Button(.refreshTimeEntries) { store?.send(.view(.refreshTapped)) }
                .keyboardShortcut("r")
                .disabled(!canUseWorkspace || store?.isBusy != false || store?.isConfigured != true)
            Divider()
            ForEach(WorkspaceFeature.Tab.allCases) { tab in
                Button(tab.title) { store?.send(.workspace(.view(.binding(.set(\.tab, tab))))) }
                    .keyboardShortcut(KeyEquivalent(tab.shortcut))
                    .disabled(!canUseWorkspace)
            }
        }
    }

    private func export() {
        guard let store, canExport else { return }
        let state = store.workspace
        let now = Date.now
        let document = state.exportDocument(data: store.data, at: now,
                                            lunchWindow: store.preferences.workspace.lunchWindow)
        store.send(.workspace(.view(.export(document))))
    }
}
