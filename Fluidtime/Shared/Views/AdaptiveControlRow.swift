import SwiftUI

/// Keeps related controls together when they fit and stacks them in narrow windows.
struct AdaptiveControlRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { content }
                .fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: 12) { content }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
