import Foundation

struct EntryDraft: Identifiable, Equatable, Sendable {
    let id: String
    var description: String
    var projectId: String
    var start: Date
    var end: Date?
    var billableOverride: Bool?

    init(entry: TimeEntry) {
        id = entry.id
        description = entry.description ?? ""
        projectId = entry.projectId ?? ""
        start = entry.start
        end = entry.end
    }
}
