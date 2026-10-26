import Foundation

struct HistoryPresentation: Equatable, Sendable {
    let scope: String
    let sections: [Section]

    struct Section: Identifiable, Equatable, Sendable {
        let id: Date
        var rows: [Row]
    }

    struct Row: Identifiable, Equatable, Sendable {
        let entry: TimeEntry
        let project: Project?
        let isPinned: Bool
        var id: String {
            entry.id
        }
    }

    struct Input: Equatable, Sendable {
        let scope: String
        let entries: [TimeEntry]
        let projects: [Project]
        let presets: [TimerPreset]
        let filter: HistoryFilter
        let calendar: Calendar
        let day: Date
    }

    private struct Pin: Hashable {
        let description: String
        let projectID: String
    }

    @concurrent
    static func prepare(_ input: Input, at now: Date) async throws -> Self {
        try make(input, at: now)
    }

    static func make(_ input: Input, at now: Date) throws -> Self {
        try Task.checkCancellation()
        let projects = Dictionary(input.projects.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let pins = Set(input.presets.filter { $0.scope == input.scope }.map {
            Pin(description: $0.description, projectID: $0.projectId)
        })
        let entries = input.filter.entries(input.entries, calendar: input.calendar, now: now)
        var sections: [Section] = []
        for entry in entries {
            try Task.checkCancellation()
            let day = input.calendar.startOfDay(for: entry.start)
            let row = Row(entry: entry, project: entry.projectId.flatMap { projects[$0] },
                          isPinned: pins.contains(Pin(description: entry.description ?? "",
                                                      projectID: entry.projectId ?? "")))
            if sections.last?.id != day {
                sections.append(Section(id: day, rows: []))
            }
            sections[sections.count - 1].rows.append(row)
        }
        return Self(scope: input.scope, sections: sections)
    }
}
