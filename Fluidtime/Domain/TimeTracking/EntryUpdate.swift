import Foundation

struct EntryUpdate: Equatable, Sendable {
    let entry: TimeEntry
    let memberId: String
    let change: Change

    enum Change: Equatable, Sendable {
        case stop(Date)
        case edit(EntryDraft, Project?)
    }
}
