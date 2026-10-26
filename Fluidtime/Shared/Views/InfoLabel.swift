import SwiftUI

struct InfoLabel: View {
    let title: LocalizedStringResource
    var explanation: LocalizedStringResource?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(title)
            if let explanation {
                InfoButton(title: title, message: explanation)
            }
        }
    }
}
