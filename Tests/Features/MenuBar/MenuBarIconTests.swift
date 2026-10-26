import AppKit
@testable import FluidtimeCore
import Testing

@MainActor
struct MenuBarIconTests {
    @Test func `active icon contains A separate visible dot`() throws {
        let image = MenuBarIcon.active
        let data = try #require(image.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: data))
        let scale = Double(bitmap.pixelsWide) / image.size.width
        let dot = try #require(bitmap.colorAt(x: Int(21 * scale), y: Int(9 * scale)))
        let gap = try #require(bitmap.colorAt(x: Int(18 * scale), y: Int(9 * scale)))

        #expect(image.isTemplate)
        #expect(image.size.width > MenuBarIcon.clock.size.width)
        #expect(dot.alphaComponent > 0.8)
        #expect(gap.alphaComponent < 0.1)
    }

    @Test(arguments: [false, true])
    func `project dot preserves its color in one cached composite image`(_ isDark: Bool) throws {
        let image = MenuBarIcon.active(projectHex: "#FF0000", isDark: isDark)
        #expect(image === MenuBarIcon.active(projectHex: "#FF0000", isDark: isDark))
        #expect(!image.isTemplate)
        #expect(image.size == MenuBarIcon.active.size)
        let data = try #require(image.tiffRepresentation)
        let bitmap = try #require(NSBitmapImageRep(data: data))
        let scale = Double(bitmap.pixelsWide) / image.size.width
        let dot = try #require(bitmap.colorAt(x: Int(21 * scale), y: Int(9 * scale))?.usingColorSpace(.sRGB))
        #expect(dot.redComponent > 0.9)
        #expect(dot.greenComponent < 0.1)
        #expect(dot.blueComponent < 0.1)
        #expect(MenuBarIcon.active(projectHex: "invalid", isDark: isDark) === MenuBarIcon.active)
        #expect(MenuBarIcon.active(projectHex: nil, isDark: isDark) === MenuBarIcon.active)
    }
}
