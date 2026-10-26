import CoreGraphics
@testable import FluidtimeCore
import Foundation
import Testing

struct TimerFeedbackPlacementTests {
    private let size = CGSize(width: 240, height: 56)
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 876)

    @Test func `feedback centers below its menu bar item`() {
        let anchor = CGRect(x: 600, y: 876, width: 80, height: 24)
        let origin = TimerFeedbackPlacement.origin(size: size, anchor: anchor, visibleFrame: screen)
        #expect(origin == CGPoint(x: 520, y: 812))
    }

    @Test(arguments: [CGFloat(0), CGFloat(1400)])
    func `feedback stays on screen near either edge`(_ positionX: CGFloat) {
        let anchor = CGRect(x: positionX, y: 876, width: 40, height: 24)
        let origin = TimerFeedbackPlacement.origin(size: size, anchor: anchor, visibleFrame: screen)
        #expect(origin.x >= screen.minX + 8)
        #expect(origin.x + size.width <= screen.maxX - 8)
        #expect(origin.y + size.height == anchor.minY - 8)
    }

    @Test func `feedback uses the status item display with negative screen coordinates`() {
        let display = CGRect(x: -1440, y: 300, width: 1440, height: 876)
        let anchor = CGRect(x: -840, y: 1176, width: 80, height: 24)
        let origin = TimerFeedbackPlacement.origin(size: size, anchor: anchor, visibleFrame: display)
        #expect(origin == CGPoint(x: -920, y: 1112))
    }

    @Test func `unavailable item falls back inside the screen`() {
        let origin = TimerFeedbackPlacement.origin(size: size, anchor: nil, visibleFrame: screen)
        #expect(origin == CGPoint(x: 1180, y: 800))
    }
}
