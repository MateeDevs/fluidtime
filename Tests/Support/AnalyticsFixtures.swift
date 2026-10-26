@testable import FluidtimeCore
import Foundation
import Testing

enum AnalyticsFixtures {
    static func date(_ text: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: text))
    }

    static func calendar(_ zone: String = "UTC") throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        calendar.firstWeekday = 2
        return calendar
    }

    static func entry(
        _ id: String, start: String, end: String?,
        billable: Bool = true, project: String? = nil, description: String = "Work"
    ) throws -> TimeEntry {
        try TimeEntry(
            id: id, start: date(start), end: end.map(date), description: description, projectId: project,
            taskId: nil, organizationId: "org", userId: "me", billable: billable, tags: []
        )
    }
}
