import SwiftUI

struct EntryHistoryRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let entry: TimeEntry
    let project: Project?
    let isPinned: Bool
    let hasActiveTimer: Bool
    let edit: () -> Void
    let start: () -> Void
    let pin: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.title).fontWeight(.medium).lineLimit(2)
                HStack {
                    ProjectLabel(project: project,
                                 fallback: entry.projectId == nil ? .noProject : .unavailableProject)
                    if entry.billable {
                        Text(.historyBillable)
                    }
                    Spacer()
                }.font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    Text(entry.start, style: .time)
                    Text(verbatim: "–")
                    if let end = entry.end {
                        Text(end, style: .time)
                    } else {
                        Text(.historyRunning)
                    }
                }.font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if let end = entry.end {
                Text(TrackedTime.clock(entry.elapsed(at: end))).monospacedDigit()
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(TrackedTime.clock(entry.elapsed(at: context.date))).monospacedDigit()
                }
            }
            Button(action: edit) { Image(systemName: "pencil") }
                .background(EntryEditorAnchorView(id: "history.\(entry.id)"))
                .help(.editEntry).accessibilityLabel(.editEntry)
            Button(action: pin) {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isPinned)
            }
            .help(isPinned ? .presetsUnpin : .presetsPin)
            .accessibilityLabel(isPinned ? .presetsUnpin : .presetsPin)
            Button(action: start) { Image(systemName: "play.fill") }
                .help(hasActiveTimer ? .stopTheCurrentTimerAndStartANewTimerFor(entry.title) :
                    .startANewTimerFor(entry.title))
                .accessibilityLabel(hasActiveTimer ? .stopTheCurrentTimerAndStartANewTimerFor(entry.title) :
                    .startANewTimerFor(entry.title))
            Button(role: .destructive, action: delete) { Image(systemName: "trash") }
                .help(.entryDelete).accessibilityLabel(.entryDelete)

        }.padding(.vertical, 6).buttonStyle(.borderless)
    }
}
