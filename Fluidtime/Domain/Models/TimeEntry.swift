import Foundation

struct TimeEntry: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let start: Date
    let end: Date?
    let description: String?
    let projectId: String?
    let taskId: String?
    let organizationId: String
    let userId: String
    let billable: Bool
    let tags: [String]

    var title: String {
        let text = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? String(localized: .noDescription) : text
    }

    func elapsed(at now: Date) -> TimeInterval {
        max(0, (end ?? now).timeIntervalSince(start))
    }
}
