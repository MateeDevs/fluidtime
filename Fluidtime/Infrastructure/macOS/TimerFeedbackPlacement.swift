import CoreGraphics
import Foundation

/// Centers feedback below the status item while keeping it inside that display's usable area.
enum TimerFeedbackPlacement {
    static func origin(size: CGSize, anchor: CGRect?, visibleFrame: CGRect) -> CGPoint {
        let margin: CGFloat = 8
        let proposedX = anchor.map { $0.midX - size.width / 2 } ?? (visibleFrame.maxX - size.width - 20)
        let proposedY = anchor.map { $0.minY - size.height - margin }
            ?? (visibleFrame.maxY - size.height - 20)
        return CGPoint(
            x: max(visibleFrame.minX + margin, min(proposedX, visibleFrame.maxX - size.width - margin)),
            y: max(visibleFrame.minY + margin, min(proposedY, visibleFrame.maxY - size.height - margin))
        )
    }
}
