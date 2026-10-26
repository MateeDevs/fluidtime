@testable import FluidtimeCore
import Foundation
import Testing

struct SolidtimeCodingTests {
    @Test func `accepts fractional timestamps without an entry type field`() throws {
        let data = Data(
            #"""
            {"id":"entry","start":"2026-10-21T10:00:00.123Z","end":null,"description":null,
            "project_id":null,"task_id":null,
            "organization_id":"org","user_id":"me","billable":false,"tags":[]}
            """#
            .utf8
        )
        let entry = try SolidtimeAPI.decoder().decode(TimeEntry.self, from: data)

        let expected = try #require(ISO8601DateFormatter().date(from: "2026-10-21T10:00:00Z")?
            .addingTimeInterval(0.123))
        #expect(abs(entry.start.timeIntervalSince(expected)) < 0.001)
        #expect(entry.title == "No description")
    }
}
