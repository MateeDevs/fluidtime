#if FLUIDTIME_ALPHA || DEBUG || SWIFT_PACKAGE
    import Foundation

    /// Fictional account shared by the Alpha build and offscreen review fixtures.
    struct AlphaSampleData: Sendable {
        static let instanceAddress = "https://example.invalid"
        static let token = "fictional-preview"
        static let memberships = [
            Membership(id: "member", organization: .init(id: "studio", name: "Design studio")),
            Membership(id: "other-member", organization: .init(id: "other", name: "Community projects"))
        ]
        static let projects = [
            Project(id: "web", name: "Website redesign", color: "#18A970", isArchived: false, isBillable: true),
            Project(id: "app", name: "Mobile application", color: "#9C6ADE", isArchived: false, isBillable: true),
            Project(id: "internal", name: "Internal projects", color: "#F79C42", isArchived: false, isBillable: false)
        ]
        static let user = SolidtimeUser(
            id: "preview-user", name: "Alex Morgan", timezone: "Europe/Prague", weekStart: "monday"
        )

        let session: SessionData

        init(now: Date) {
            let calendar = Self.user.calendar
            let today = calendar.startOfDay(for: now)
            var entries: [TimeEntry] = []
            for day in 1 ... 35 {
                guard let date = calendar.date(byAdding: .day, value: -day, to: today) else { continue }
                for (hour, hours) in [(9, 3.0), (13, 2.0), (15, 1.5)] {
                    guard let start = calendar.date(byAdding: .hour, value: hour, to: date) else { continue }
                    entries.append(Self.entry(
                        "day-\(day)-\(hour)", start: start, end: start.addingTimeInterval(hours * 3600),
                        project: Self.projects[day % 3].id,
                        description: ["Design review", "Navigation and onboarding", "Weekly planning",
                                      "Prototype updates", "Project administration", "Accessibility review",
                                      "Development planning"][day % 7]
                    ))
                }
            }
            let running = Self.entry("running", start: now.addingTimeInterval(-2700), end: nil)
            session = SessionData(
                user: Self.user, memberships: Self.memberships, selectedMembershipId: Self.memberships[0].id,
                projects: Self.projects, entries: [running] + entries.sorted { $0.start > $1.start },
                active: running, lastSynced: now, lastFullSync: now,
                syncedWeekStart: calendar.dateInterval(of: .weekOfYear, for: now)?.start
            )
        }

        static func entry(
            _ id: String, start: Date, end: Date?, project: String? = "web",
            description: String = "Design review", organization: String = "studio"
        ) -> TimeEntry {
            TimeEntry(id: id, start: start, end: end, description: description, projectId: project,
                      taskId: nil, organizationId: organization, userId: user.id,
                      billable: project != nil && project != "internal", tags: [])
        }
    }
#endif
