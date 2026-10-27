import ComposableArchitecture
import SwiftUI

@ViewAction(for: WorkspaceFeature.self)
struct MainTimerDisclosure: View {
    let store: StoreOf<WorkspaceFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            send(.binding(.set(\.isTimerCollapsed, !store.isTimerCollapsed)),
                 animation: reduceMotion ? nil : .easeInOut(duration: 0.24))
        } label: {
            Image(systemName: "chevron.down")
                .rotationEffect(.degrees(store.isTimerCollapsed ? -90 : 0))
                .frame(width: 20, height: 22)
        }
        .buttonStyle(.borderless)
        .help(store.isTimerCollapsed ? .timerExpand : .timerCollapse)
        .accessibilityLabel(store.isTimerCollapsed ? .timerExpand : .timerCollapse)
        .accessibilityIdentifier("main-timer-disclosure")
    }
}
