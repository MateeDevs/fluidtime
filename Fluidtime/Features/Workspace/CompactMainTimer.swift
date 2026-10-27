import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct CompactMainTimer: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(store.active == nil ? Color.secondary : .green)
                .frame(width: 6, height: 6)
                .accessibilityLabel(store.active == nil ? .newTimer : .timerRunning)
            if let entry = store.active {
                Text(entry.title)
                    .lineLimit(1).truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .help(entry.title)
                if !store.activeInAnotherOrganization {
                    TrackerEditingControls(store: store, entry: entry, style: .window)
                }
                TrackerElapsedTime(entry: entry, isCompact: true)
            } else {
                TextField(String(localized: .whatAreYouWorkingOn), text: $store.description)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(.description)
                    .disabled(store.isBusy || store.destination != nil)
            }
            TrackerPrimaryButton(store: store, isCompact: true)
        }
        .accessibilityIdentifier("main-timer-compact")
    }
}
