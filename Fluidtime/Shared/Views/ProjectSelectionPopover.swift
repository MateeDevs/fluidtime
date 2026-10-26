import SwiftUI

struct ProjectSelectionPopover: View {
    let projects: [Project]
    @Binding var selected: String
    let allowsAllProjects: Bool
    let dismiss: () -> Void
    @State private var search = ""
    @State private var highlighted: String?
    @FocusState private var searchIsFocused: Bool

    var body: some View {
        let matches = projects.filter { search.isEmpty || $0.name.localizedStandardContains(search) }
        VStack(spacing: 0) {
            TextField(String(localized: .projectsSearch), text: $search)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(.projectsSearch)
                .focused($searchIsFocused)
                .onSubmit { choose(matches.first?.id) }
                .padding(12)
            Divider()
            List(selection: $highlighted) {
                if search.isEmpty {
                    if allowsAllProjects {
                        choice("all") { Text(.historyAllProjects) }
                    }
                    choice("") { Text(.noProject) }
                }
                ForEach(matches) { project in
                    choice(project.id) { ProjectLabel(project: project).lineLimit(1) }
                }
            }
            .listStyle(.plain)
            .overlay {
                if matches.isEmpty, !search.isEmpty {
                    Text(.projectsNoMatches).foregroundStyle(.secondary)
                }
            }
            .onKeyPress(.return) {
                choose(highlighted)
                return .handled
            }
        }
        .frame(width: 320, height: 340)
        .onAppear {
            highlighted = selected
            searchIsFocused = true
        }
        .onExitCommand(perform: dismiss)
    }

    private func choice(_ id: String, @ViewBuilder label: () -> some View) -> some View {
        Button { choose(id) } label: {
            HStack {
                label()
                Spacer()
                if selected == id {
                    Image(systemName: "checkmark").accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .tag(id)
    }

    private func choose(_ id: String?) {
        guard let id else { return }
        selected = id
        dismiss()
    }
}
