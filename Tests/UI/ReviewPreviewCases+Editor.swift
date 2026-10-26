import AppKit
import ComposableArchitecture
@testable import FluidtimeCore
import Testing

extension ReviewPreviewFixtures {
    func editorCases() throws -> [ReviewPreviewCase] {
        let running = try #require(state.data.active)
        let completed = try #require(state.data.entries.first { $0.end != nil })
        let entries = [
            ("editor-running", running), ("editor-completed", completed),
            ("editor-saving", completed), ("editor-error", completed),
            ("editor-long-description", completed), ("editor-no-project", completed)
        ]
        return try entries.map { name, entry in
            var item = preview(name, .editor)
            var editor = try EntryEditorFeature.State(
                draft: EntryDraft(entry: entry), entry: entry,
                connection: #require(state.connection), membership: state.memberships[0],
                projects: state.availableProjects
            )
            if name == "editor-saving" {
                editor.isSaving = true; editor.showsProgress = true
            }
            if name == "editor-error" {
                editor.error = String(localized: .editorInvalidDates)
            }
            if name == "editor-long-description" {
                editor.draft.description = Array(
                    repeating: "Review navigation, onboarding, and accessibility with the product team.",
                    count: 5
                )
                .joined(separator: "\n")
            }
            if name == "editor-no-project" {
                editor.draft.projectId = ""
            }
            item.editor = editor
            return item
        }
    }

    func feedbackCases() throws -> [ReviewPreviewCase] {
        let running = try #require(state.active)
        let completed = try #require(state.data.entries.first { $0.end != nil })
        let long = Self.entry("long", start: now.addingTimeInterval(-2700), end: nil,
                              description: Self.longDescription)
        return [
            preview("feedback-started", .feedback(.started(running))),
            preview("feedback-started-long", .feedback(.started(long))),
            preview("feedback-stopped", .feedback(.stopped(completed))),
            preview("feedback-failed", .feedback(.failed)),
            preview("feedback-idle-reminder", .feedback(.idleReminder)),
            preview("feedback-long-reminder", .feedback(.longRunningReminder))
        ]
    }
}
