import Foundation

extension SolidtimeAPI {
    func entries(membership: Membership, since: Date? = nil) async throws -> [TimeEntry] {
        var entries: [TimeEntry] = []
        while true {
            try Task.checkCancellation()
            var query = [
                URLQueryItem(name: "member_id", value: membership.id),
                URLQueryItem(name: "limit", value: "500"),
                URLQueryItem(name: "offset", value: String(entries.count))
            ]
            if let since {
                query.append(URLQueryItem(name: "start", value: Self.timestamp(since)))
            }
            let response: CollectionPage<TimeEntry> = try await request(
                "organizations/\(membership.organization.id)/time-entries", query: query
            )
            entries += response.data
            guard let total = response.meta?.total else {
                throw AppError.message(String(localized: .solidtimeDidntReturnTheNumberOfTimeEntries))
            }
            if entries.count >= total {
                break
            }
            if response.data.isEmpty {
                throw AppError.message(String(localized: .couldntLoadAllTimeEntriesRefreshToTryAgain))
            }
        }
        return entries
    }

    func create(
        membership: Membership,
        description: String,
        project: Project?,
        at date: Date = Date()
    ) async throws -> TimeEntry {
        let body: [String: Any] = [
            "member_id": membership.id, "description": description,
            "project_id": project?.id as Any? ?? NSNull(), "task_id": NSNull(),
            "start": Self.timestamp(date), "end": NSNull(),
            "billable": project?.isBillable ?? false, "type": "work"
        ]
        let response: Envelope<TimeEntry> = try await request(
            "organizations/\(membership.organization.id)/time-entries", method: "POST", body: body
        )
        return response.data
    }

    func update(_ entry: TimeEntry, memberId: String, changes: [String: Any]) async throws -> TimeEntry {
        var body = changes
        body["member_id"] = memberId
        let response: Envelope<TimeEntry> = try await request(
            "organizations/\(entry.organizationId)/time-entries/\(entry.id)", method: "PUT", body: body
        )
        return response.data
    }

    func delete(_ entry: TimeEntry) async throws {
        try await requestWithoutResponse(
            "organizations/\(entry.organizationId)/time-entries/\(entry.id)", method: "DELETE"
        )
    }
}
