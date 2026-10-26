import SwiftUI

/// Relative positions within the day's attendance span; gaps remain visible between work intervals.
struct DailyWorkTimeline: View {
    let day: WorkDay

    var body: some View {
        Canvas { context, size in
            guard let start = day.firstStart, let end = day.lastEnd, end > start else { return }
            let span = end.timeIntervalSince(start)
            for interval in day.workIntervals {
                context.fill(Path(rect(interval, start: start, span: span, size: size)), with: .color(.accentColor))
            }
            if let lunch = day.lunchInterval {
                context.fill(Path(rect(lunch, start: start, span: span, size: size)), with: .color(.orange))
            }
        }
        .frame(height: 8)
        .background(.quaternary, in: Capsule())
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    private func rect(_ interval: DateInterval, start: Date, span: TimeInterval, size: CGSize) -> CGRect {
        let lower = max(0, min(1, interval.start.timeIntervalSince(start) / span))
        let upper = max(lower, min(1, interval.end.timeIntervalSince(start) / span))
        return CGRect(x: lower * size.width, y: 0, width: (upper - lower) * size.width, height: size.height)
    }
}
