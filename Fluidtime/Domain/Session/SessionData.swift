import Foundation

struct SessionData: Equatable, Sendable {
    var user: SolidtimeUser?
    var memberships: [Membership] = []
    var selectedMembershipId = ""
    var projects: [Project] = []
    var entries: [TimeEntry] = []
    var active: TimeEntry?
    var lastSynced: Date?
    var lastFullSync: Date?
    var syncedWeekStart: Date?

    var membership: Membership? {
        memberships.first { $0.id == selectedMembershipId }
    }

    var availableProjects: [Project] {
        projects.filter { !$0.isArchived }
    }

    var activeInAnotherOrganization: Bool {
        guard let active, let membership else { return false }
        return active.organizationId != membership.organization.id
    }

    var recentEntries: [TimeEntry] {
        var seen = Set<String>()
        return entries.sorted { $0.start > $1.start }.filter {
            $0.end != nil
                && seen.insert(($0.description ?? "") + "\u{0}" + ($0.projectId ?? "")).inserted
        }.prefix(5).map(\.self)
    }

    mutating func clearEntries() {
        projects = []
        entries = []
        active = nil
        lastSynced = nil
        lastFullSync = nil
        syncedWeekStart = nil
    }

    mutating func apply(_ entry: TimeEntry, at now: Date) {
        entries.removeAll { $0.id == entry.id }
        if entry.organizationId == membership?.organization.id {
            entries.append(entry)
        }
        if entry.end == nil {
            active = entry
        } else if active?.id == entry.id {
            active = nil
        }
        lastSynced = now
    }

    mutating func applyStoppedTimer(_ entry: TimeEntry, at now: Date) {
        if active?.id != entry.id {
            lastFullSync = nil
        }
        entries.removeAll { $0.end == nil }
        active = nil
        apply(entry, at: now)
    }

    func projectName(_ id: String?) -> String {
        guard let id else { return String(localized: .noProject) }
        return projects.first { $0.id == id }?.name ?? String(localized: .unavailableProject)
    }

    func selectedProject(_ id: String) throws -> Project? {
        guard !id.isEmpty else { return nil }
        guard let project = availableProjects.first(where: { $0.id == id }) else {
            throw AppError.message(String(localized: .chooseAnAvailableProjectBeforeSaving))
        }
        return project
    }

    func ownedMembership(for entry: TimeEntry) throws -> Membership {
        guard entry.userId == user?.id,
              let membership = memberships.first(where: { $0.organization.id == entry.organizationId })
        else {
            throw AppError.message(String(localized: .thisEntryDoesntBelongToYourAccountRefreshAndTryAgain))
        }
        return membership
    }

    func totals(at now: Date) -> (today: TimeInterval, week: TimeInterval) {
        (
            total(in: .day, at: now),
            total(in: .weekOfYear, at: now)
        )
    }

    func total(in component: Calendar.Component, at now: Date) -> TimeInterval {
        guard let interval = user?.calendar.dateInterval(of: component, for: now) else { return 0 }
        return TrackedTime.total(entries, in: interval, now: now)
    }
}
