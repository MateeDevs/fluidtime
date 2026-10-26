import Foundation

/// Builds a snapshot without changing reducer state until every read succeeds.
struct SessionSync {
    let client: SolidtimeClient

    func fetch(
        connection: Connection, previous: SessionData, preferredMembershipId: String,
        full: Bool, now: Date
    ) async throws -> SessionData {
        var data = previous
        let reloadAccount = full || data.user == nil || now.timeIntervalSince(data.lastFullSync ?? .distantPast) > 300
        if reloadAccount {
            async let user = client.user(connection)
            async let memberships = client.memberships(connection)
            (data.user, data.memberships) = try await (user, memberships)
            if !data.memberships.contains(where: { $0.id == data.selectedMembershipId }) {
                data.clearEntries()
                data.selectedMembershipId =
                    data.memberships.first { $0.id == preferredMembershipId }?.id ?? data.memberships.first?.id ?? ""
            }
        }
        guard let user = data.user, let membership = data.membership else {
            throw AppError.message(String(localized: .joinAnOrganizationOnYourInstanceWebpageToStartTrackingTime))
        }
        let weekStart = user.calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let active = try await client.activeEntry(connection)
        let needsFull =
            reloadAccount || data.lastFullSync == nil || data.syncedWeekStart != weekStart
                || data.active?.id != active?.id
        async let entries = client.entries(connection, membership, needsFull ? nil : weekStart)
        let projects = needsFull ? try await client.projects(connection, membership.organization.id) : data.projects
        var snapshot = try await entries
        if !needsFull {
            snapshot += data.entries.filter { $0.start < weekStart }
        }
        snapshot.removeAll { $0.end == nil }
        if let active, active.organizationId == membership.organization.id {
            snapshot.append(active)
        }
        try Task.checkCancellation()
        var seen = Set<String>()
        data.entries = snapshot.filter { $0.userId == user.id && seen.insert($0.id).inserted }
        data.projects = projects
        data.active = active
        data.lastSynced = now
        data.syncedWeekStart = weekStart
        if needsFull {
            data.lastFullSync = now
        }
        return data
    }
}
