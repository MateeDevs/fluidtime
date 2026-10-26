import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct PinnedTasksView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(.presetsTitle).font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(store.pinnedPresets) { preset in
                    Button { send(.startPreset(preset)) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill").font(.caption)
                            Text(preset.title).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.bordered)
                    .help(store.active == nil ? .startANewTimerFor(preset.title)
                        : .stopTheCurrentTimerAndStartANewTimerFor(preset.title))
                    .accessibilityLabel(store.active == nil ? .startANewTimerFor(preset.title)
                        : .stopTheCurrentTimerAndStartANewTimerFor(preset.title))
                    .contextMenu {
                        Button { send(.removePreset(preset.id)) } label: {
                            Label(.presetsUnpin, systemImage: "pin.slash")
                        }
                    }
                }
            }
        }
        .disabled(store.isBusy || store.destination != nil)
    }
}
