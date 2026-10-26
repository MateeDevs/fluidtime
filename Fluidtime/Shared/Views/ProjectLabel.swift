import SwiftUI

struct ProjectLabel: View {
    let project: Project?
    var fallback: LocalizedStringResource = .noProject

    var body: some View {
        HStack(spacing: 7) {
            ProjectColorDot(hex: project?.color)
            if let project {
                Text(project.name)
            } else {
                Text(fallback)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ProjectColorDot: View {
    let hex: String?

    var body: some View {
        Circle().fill(Color(projectHex: hex)).frame(width: 8, height: 8)
            .padding(3).background(Color(projectHex: hex).opacity(0.18), in: Circle())
            .accessibilityHidden(true)
    }
}

extension Color {
    init(projectHex: String?) {
        let hex = (projectHex ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6, let number = UInt64(hex, radix: 16) else {
            self.init(nsColor: .secondaryLabelColor)
            return
        }
        self.init(.sRGB, red: Double((number >> 16) & 255) / 255,
                  green: Double((number >> 8) & 255) / 255, blue: Double(number & 255) / 255, opacity: 1)
    }
}
