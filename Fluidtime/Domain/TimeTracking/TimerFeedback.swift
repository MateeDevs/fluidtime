import Foundation

enum TimerFeedback: Equatable, Sendable {
    case started(TimeEntry)
    case stopped(TimeEntry)
    case failed
    case idleReminder
    case longRunningReminder
}

extension TimerFeedback {
    var title: LocalizedStringResource {
        switch self {
        case .started: .feedbackTimerStarted
        case .stopped: .feedbackTimerStopped
        case .failed: .feedbackFailed
        case .idleReminder, .longRunningReminder: .reminderTimerRunning
        }
    }

    var detail: String {
        switch self {
        case let .started(entry): entry.title
        case let .stopped(entry): TrackedTime.clock(entry.elapsed(at: entry.end ?? .now))
        case .failed: String(localized: .feedbackReview)
        case .idleReminder: String(localized: .feedbackReminderIdle)
        case .longRunningReminder: String(localized: .feedbackReminderLong)
        }
    }
}
