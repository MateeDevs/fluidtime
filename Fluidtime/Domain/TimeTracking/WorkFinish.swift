import Foundation

enum WorkFinish: Equatable, Sendable {
    case targetReached
    case expected(Date)

    static func calculate(targetHours: Double, tracked: TimeInterval, now: Date) -> Self? {
        guard targetHours.isFinite, targetHours > 0, tracked.isFinite else { return nil }
        let remaining = max(0, targetHours * 3600 - max(0, tracked))
        return remaining == 0 ? .targetReached : .expected(now.addingTimeInterval(remaining))
    }
}
