import ComposableArchitecture
import Foundation

@DependencyClient
struct SolidtimeClient: Sendable {
    var user: @Sendable (Connection) async throws -> SolidtimeUser
    var memberships: @Sendable (Connection) async throws -> [Membership]
    var activeEntry: @Sendable (Connection) async throws -> TimeEntry?
    var projects: @Sendable (Connection, String) async throws -> [Project]
    var entries: @Sendable (Connection, Membership, Date?) async throws -> [TimeEntry]
    var create: @Sendable (Connection, Membership, String, Project?, Date) async throws -> TimeEntry
    var delete: @Sendable (Connection, TimeEntry) async throws -> Void
    var update: @Sendable (Connection, EntryUpdate) async throws -> TimeEntry
}

extension SolidtimeClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var solidtime: SolidtimeClient {
        get { self[SolidtimeClient.self] }
        set { self[SolidtimeClient.self] = newValue }
    }
}
