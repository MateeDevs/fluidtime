import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct TrackerEditingControls: View {
    let store: StoreOf<AppFeature>
    let entry: TimeEntry
    let style: TimerTrackerView.Style

    private var anchor: String {
        "tracker.\(style == .panel ? "panel" : "window").\(entry.id)"
    }

    private var isPinned: Bool {
        store.pinnedPresets.contains {
            $0.description == (entry.description ?? "") && $0.projectId == (entry.projectId ?? "")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button { send(.editTapped(entry, anchor: anchor)) } label: { Image(systemName: "pencil") }
                .background(EntryEditorAnchorView(id: anchor))
                .help(.editEntry).accessibilityLabel(.editEntry)
            Button { send(.pinEntry(entry)) } label: { Image(systemName: isPinned ? "pin.fill" : "pin") }
                .help(isPinned ? .presetsUnpin : .presetsPin)
                .accessibilityLabel(isPinned ? .presetsUnpin : .presetsPin)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .disabled(store.isBusy || store.destination != nil)
    }
}
