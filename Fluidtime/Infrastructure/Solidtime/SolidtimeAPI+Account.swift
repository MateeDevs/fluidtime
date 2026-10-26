import Foundation

extension SolidtimeAPI {
    func user() async throws -> SolidtimeUser {
        let response: Envelope<SolidtimeUser> = try await request("users/me")
        return response.data
    }

    func memberships() async throws -> [Membership] {
        let response: Envelope<[Membership]> = try await request("users/me/memberships")
        return response.data
    }

    func activeEntry() async throws -> TimeEntry? {
        do {
            let response: Envelope<TimeEntry?> = try await request("users/me/time-entries/active")
            return response.data
        } catch AppError.http(404) { return nil }
    }
}
