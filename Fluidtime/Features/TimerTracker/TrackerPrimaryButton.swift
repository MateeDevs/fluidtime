import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct TrackerPrimaryButton: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        Button {
            send(store.active == nil ? .startTapped : .stopTapped)
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Image(systemName: store.active == nil ? "play.fill" : "stop.fill")
                        .opacity(store.showsProgress ? 0 : 1)
                    if store.showsProgress {
                        ProgressView().controlSize(.small).frame(width: 16, height: 16)
                    }
                }.frame(width: 16, height: 16)
                Text(store.active == nil ? .trackerStart : .trackerStop)
            }.frame(minWidth: 72)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .help(store.active == nil ? .startTimer : .stopTimer)
        .accessibilityLabel(store.active == nil ? .startTimer : .stopTimer)
        .disabled(store.isBusy || store.destination != nil || (store.active == nil && store.lastSynced == nil))
    }
}
