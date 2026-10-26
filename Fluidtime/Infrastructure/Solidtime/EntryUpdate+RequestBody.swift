import Foundation

extension EntryUpdate {
    var body: [String: Any] {
        switch change {
        case let .stop(date): return ["end": SolidtimeAPI.timestamp(date)]
        case let .edit(draft, project):
            var changes: [String: Any] = [:]
            if draft.description != (entry.description ?? "") {
                changes["description"] = draft.description
            }
            if draft.start != entry.start {
                changes["start"] = SolidtimeAPI.timestamp(draft.start)
            }
            if let end = draft.end, end != entry.end {
                changes["end"] = SolidtimeAPI.timestamp(end)
            }
            if draft.projectId != (entry.projectId ?? "") {
                changes["project_id"] = project?.id as Any? ?? NSNull()
                changes["task_id"] = NSNull()
                changes["billable"] = draft.billableOverride ?? project?.isBillable ?? false
            } else if let billable = draft.billableOverride, billable != entry.billable {
                changes["billable"] = billable
            }
            return changes
        }
    }
}
