import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct TrackerPrimaryButton: View {
    let store: StoreOf<AppFeature>
    var isCompact = false
    var showsFullTitle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            send(store.active == nil ? .startTapped : .stopTapped)
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Image(systemName: store.active == nil ? "play.fill" : "stop.fill")
                        .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: store.active != nil)
                        .opacity(store.showsProgress ? 0 : 1)
                    if store.showsProgress {
                        ProgressView().controlSize(.small).frame(width: 16, height: 16)
                            .transition(reduceMotion ? .identity : .opacity)
                    }
                }
                .frame(width: 16, height: 16)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: store.showsProgress)
                Text(title)
            }.frame(minWidth: isCompact ? 0 : 72)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(isCompact ? .small : .large)
        .help(store.active == nil ? .startTimer : .stopTimer)
        .accessibilityLabel(store.active == nil ? .startTimer : .stopTimer)
        .disabled(store.isBusy || store.destination != nil || (store.active == nil && store.lastSynced == nil))
    }

    private var title: LocalizedStringResource {
        if showsFullTitle {
            return store.active == nil ? .startTimer : .stopTimer
        }
        return store.active == nil ? .trackerStart : .trackerStop
    }
}
