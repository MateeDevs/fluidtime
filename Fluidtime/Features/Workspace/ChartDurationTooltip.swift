import SwiftUI

struct ChartDurationTooltip<Title: View>: View {
    let duration: TimeInterval
    @ViewBuilder let title: Title

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            title.font(.caption).foregroundStyle(.secondary)
            Text(TrackedTime.clock(duration)).font(.headline.monospacedDigit())
        }
        .padding(10)
        .frame(maxWidth: 240, alignment: .leading)
        .fixedSize(horizontal: true, vertical: true)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8).strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
