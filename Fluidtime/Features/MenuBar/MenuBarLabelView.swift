import Combine
import ComposableArchitecture
import Foundation
import SwiftUI

struct MenuBarLabelView: View {
    let store: StoreOf<AppFeature>
    @Environment(\.colorScheme) private var colorScheme
    @State private var now = Date()
    /// A TimelineView here can repeatedly invalidate the menu bar host during launch.
    private let ticks = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let presentation = MenuBarPresentation(data: store.data, preferences: store.preferences, now: now)
        HStack(spacing: 4) {
            // MenuBarExtra merges one image and text; additional images can be discarded.
            Image(nsImage: presentation.showsActiveIndicator
                ? MenuBarIcon.active(projectHex: presentation.activeProjectColor, isDark: colorScheme == .dark)
                : MenuBarIcon.clock)
            #if FLUIDTIME_ALPHA
                Text(.alphaMenuBarText(presentation.text ?? "")).monospacedDigit()
            #else
                if let text = presentation.text {
                    Text(text).monospacedDigit()
                }
            #endif
        }
        .onReceive(ticks) { now = $0 }
        #if FLUIDTIME_ALPHA
            .accessibilityLabel(.alphaMenuBarAccessibility(presentation.accessibilityLabel))
        #else
            .accessibilityLabel(presentation.accessibilityLabel)
        #endif
    }
}
