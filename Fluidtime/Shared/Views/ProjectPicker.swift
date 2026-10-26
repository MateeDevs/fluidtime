import SwiftUI

struct ProjectPicker: View {
    let projects: [Project]
    @Binding var selected: String
    var currentProject: Project?
    var allowsAllProjects = false
    var showsLabel = true
    @State private var isPresented = false

    private var isPreservedAssignment: Bool {
        !selected.isEmpty && !(allowsAllProjects && selected == "all") && !projects.contains { $0.id == selected }
    }

    private var selectionTitle: String {
        if allowsAllProjects, selected == "all" {
            return String(localized: .historyAllProjects)
        }
        return (projects.first { $0.id == selected } ?? currentProject)?.name
            ?? String(localized: isPreservedAssignment ? .unavailableProject : .noProject)
    }

    var body: some View {
        if showsLabel {
            LabeledContent { selectionButton } label: { Text(.project) }
        } else {
            selectionButton
        }
    }

    private var selectionButton: some View {
        Button { isPresented.toggle() } label: {
            HStack(spacing: 8) {
                if allowsAllProjects, selected == "all" {
                    Text(.historyAllProjects)
                } else {
                    ProjectLabel(project: projects.first { $0.id == selected } ?? currentProject,
                                 fallback: isPreservedAssignment ? .unavailableProject : .noProject)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(.project)
        .accessibilityValue(selectionTitle)
        .help(isPreservedAssignment
            ? String(localized: .projectsCurrentAssignmentHelp) : selectionTitle)
        .accessibilityHint(isPreservedAssignment ? String(localized: .projectsCurrentAssignmentHelp) : "")
        .popover(isPresented: $isPresented) {
            ProjectSelectionPopover(projects: projects, selected: $selected, allowsAllProjects: allowsAllProjects) {
                isPresented = false
            }
        }
    }
}
