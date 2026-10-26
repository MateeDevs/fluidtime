import AppKit

@MainActor
enum MenuBarIcon {
    static let clock = makeImage(showsActiveIndicator: false)
    static let active = makeImage(showsActiveIndicator: true)
    private struct ProjectIcon {
        let hex: String
        let isDark: Bool
        let image: NSImage
    }

    private static var cachedProjectIcon: ProjectIcon?

    static func active(projectHex: String?, isDark: Bool) -> NSImage {
        guard let projectHex else { return active }
        let hex = projectHex.hasPrefix("#") ? String(projectHex.dropFirst()) : projectHex
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return active }
        if let cachedProjectIcon, cachedProjectIcon.hex == hex, cachedProjectIcon.isDark == isDark {
            return cachedProjectIcon.image
        }
        let color = NSColor(srgbRed: Double((value >> 16) & 255) / 255,
                            green: Double((value >> 8) & 255) / 255,
                            blue: Double(value & 255) / 255, alpha: 1)
        let image = makeImage(showsActiveIndicator: true, indicatorColor: color, isDark: isDark)
        cachedProjectIcon = ProjectIcon(hex: hex, isDark: isDark, image: image)
        return image
    }

    private static func makeImage(
        showsActiveIndicator: Bool,
        indicatorColor: NSColor? = nil,
        isDark: Bool = false
    ) -> NSImage {
        let image = NSImage(size: NSSize(width: showsActiveIndicator ? 24 : 18, height: 18), flipped: false) { _ in
            var symbol = NSImage(systemSymbolName: "clock", accessibilityDescription: nil)
            if indicatorColor != nil {
                symbol = symbol?.withSymbolConfiguration(.init(paletteColors: [isDark ? .white : .black]))
            }
            symbol?.draw(in: NSRect(x: 1, y: 1, width: 16, height: 16))
            if showsActiveIndicator {
                (indicatorColor ?? NSColor.labelColor).setFill()
                NSBezierPath(ovalIn: NSRect(x: 19, y: 7, width: 5, height: 5)).fill()
            }
            return true
        }
        image.isTemplate = indicatorColor == nil
        return image
    }
}
