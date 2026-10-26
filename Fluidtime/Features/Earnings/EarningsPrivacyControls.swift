import ComposableArchitecture
import SwiftUI

@ViewAction(for: EarningsFeature.self)
struct EarningsPrivacyControls: View {
    let store: StoreOf<EarningsFeature>
    let surface: EarningsFeature.Surface

    var body: some View {
        HStack {
            if store.showsProgress {
                ProgressView().controlSize(.small).accessibilityLabel(.earningsUnlocking)
            }
            Button {
                send(store.surface == surface ? .conceal(surface) : .reveal(surface))
            } label: {
                Image(systemName: store.surface == surface ? "eye.slash" : "touchid")
            }
            .help(store.surface == surface ? .earningsConceal : .earningsReveal)
            .accessibilityLabel(store.surface == surface ? .earningsConceal : .earningsReveal)
            .disabled(store.accountScope.isEmpty || store.operation != nil)
        }
    }
}
