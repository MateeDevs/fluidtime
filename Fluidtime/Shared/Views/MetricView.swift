import SwiftUI

struct MetricView: View {
    let title: LocalizedStringResource
    let value: String
    var explanation: LocalizedStringResource?

    var body: some View {
        GroupBox {
            Text(value).font(.title2.monospacedDigit()).fontWeight(.medium)
                .accessibilityLabel(title).accessibilityValue(value)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
        } label: {
            InfoLabel(title: title, explanation: explanation).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
    }
}
