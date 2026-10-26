import SwiftUI

/// Four metrics stay balanced in two columns until all four fit comfortably.
struct MetricGrid<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            grid(columns: 4).frame(minWidth: 740)
            grid(columns: 2)
        }
    }

    private func grid(columns: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
            content
        }
    }
}
