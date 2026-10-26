import SwiftUI

struct AccountLoadingView: View {
    let showsProgress: Bool

    var body: some View {
        VStack(spacing: 12) {
            if showsProgress {
                ProgressView().controlSize(.small).accessibilityLabel(.accountLoading)
                Text(.accountLoading).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
