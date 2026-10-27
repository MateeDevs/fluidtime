#if FLUIDTIME_ALPHA || DEBUG || SWIFT_PACKAGE
    import Foundation

    /// Local server substitute. All mutations remain in this actor until the application quits.
    actor AlphaSession {
        private var entries: [TimeEntry]

        init(sample: AlphaSampleData) {
            entries = sample.session.entries
        }

        func user(_ connection: Connection) throws -> SolidtimeUser {
            try validate(connection)
            return AlphaSampleData.user
        }

        func memberships(_ connection: Connection) throws -> [Membership] {
            try validate(connection)
            return AlphaSampleData.memberships
        }

        func activeEntry(_ connection: Connection) throws -> TimeEntry? {
            try validate(connection)
            return entries.first { $0.end == nil }
        }

        func projects(_ connection: Connection, organization: String) throws -> [Project] {
            try validate(connection)
            return AlphaSampleData.memberships.contains { $0.organization.id == organization }
                ? AlphaSampleData.projects : []
        }

        func history(_ connection: Connection, membership: Membership, since: Date?) throws -> [TimeEntry] {
            try validate(connection)
            return entries.filter { entry in
                entry.organizationId == membership.organization.id && entry.userId == AlphaSampleData.user.id
                    && (since.map { entry.start >= $0 } ?? true)
            }.sorted { $0.start > $1.start }
        }

        func create(
            _ connection: Connection, membership: Membership, description: String, project: Project?, at date: Date
        ) throws -> TimeEntry {
            try validate(connection)
            guard entries.allSatisfy({ $0.end != nil }) else {
                throw AppError.message(String(localized: .youAlreadyHaveARunningTimerStopItBeforeStartingAnother))
            }
            guard AlphaSampleData.memberships.contains(membership) else { throw AppError.http(403) }
            let entry = TimeEntry(
                id: UUID().uuidString, start: date, end: nil, description: description, projectId: project?.id,
                taskId: nil, organizationId: membership.organization.id, userId: AlphaSampleData.user.id,
                billable: project?.isBillable ?? false, tags: []
            )
            entries.append(entry)
            return entry
        }

        func update(_ connection: Connection, update: EntryUpdate) throws -> TimeEntry {
            try validate(connection)
            let index = try index(of: update.entry)
            let current = entries[index]
            guard AlphaSampleData.memberships.contains(where: {
                $0.id == update.memberId && $0.organization.id == current.organizationId
            }) else { throw AppError.http(403) }
            let entry: TimeEntry
            switch update.change {
            case let .stop(date):
                entry = TimeEntry(
                    id: current.id, start: current.start, end: date, description: current.description,
                    projectId: current.projectId, taskId: current.taskId, organizationId: current.organizationId,
                    userId: current.userId, billable: current.billable, tags: current.tags
                )
            case let .edit(draft, project):
                let changedProject = draft.projectId != (current.projectId ?? "")
                entry = TimeEntry(
                    id: current.id, start: draft.start, end: draft.end, description: draft.description,
                    projectId: draft.projectId.isEmpty ? nil : draft.projectId,
                    taskId: changedProject ? nil : current.taskId, organizationId: current.organizationId,
                    userId: current.userId,
                    billable: draft
                        .billableOverride ?? (changedProject ? project?.isBillable ?? false : current.billable),
                    tags: current.tags
                )
            }
            entries[index] = entry
            return entry
        }

        func delete(_ connection: Connection, entry: TimeEntry) throws {
            try validate(connection)
            try entries.remove(at: index(of: entry))
        }

        private func index(of entry: TimeEntry) throws -> Int {
            guard let index = entries.firstIndex(where: {
                $0.id == entry.id && $0.organizationId == entry.organizationId && $0.userId == AlphaSampleData.user.id
            }) else { throw AppError.http(404) }
            return index
        }

        private func validate(_ connection: Connection) throws {
            guard connection.instance.absoluteString == AlphaSampleData.instanceAddress else {
                throw AppError.message(String(localized: .alphaConnectionOnly))
            }
            try Task.checkCancellation()
        }
    }
#endif
