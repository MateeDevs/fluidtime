import SwiftUI

struct InfoButton: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    @State private var isPresented = false

    var body: some View {
        Button { isPresented.toggle() } label: { Image(systemName: "info.circle") }
            .buttonStyle(.borderless)
            .controlSize(.mini)
            .foregroundStyle(.secondary)
            .help(.infoAbout(String(localized: title)))
            .accessibilityLabel(.infoAbout(String(localized: title)))
            .popover(isPresented: $isPresented, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title).font(.headline)
                    Text(message).fixedSize(horizontal: false, vertical: true)
                }
                .font(.callout)
                .foregroundStyle(.primary)
                .padding(20)
                .frame(width: 320)
            }
    }
}
