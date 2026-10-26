import ComposableArchitecture
import SwiftUI

extension MenuBarView {
    @ViewBuilder
    var errorBanner: some View {
        if let error = store.error {
            VStack(alignment: .leading, spacing: 8) {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button(.refreshTimeEntries) { send(.refreshTapped) }
                        .disabled(store.isBusy || !store.isConfigured)
                    Button(.settings) { showSettings() }
                }
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .contain)
        }
    }
}
