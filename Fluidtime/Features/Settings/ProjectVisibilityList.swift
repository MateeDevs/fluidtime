import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct ProjectVisibilityList: View {
    let store: StoreOf<AppFeature>
    @State private var search = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let projects = store.availableProjects
        let hidden = store.hiddenProjectIDs
        let matches = projects.filter { search.isEmpty || $0.name.localizedStandardContains(search) }
        VStack(alignment: .leading, spacing: 12) {
            Text(.projectsVisibilityTitle).font(.headline)
            TextField(String(localized: .projectsSearch), text: $search)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(.projectsSearch)
            HStack {
                Button(.projectsSelectAll) { send(.allProjectsVisibilityChanged(isVisible: true)) }
                    .disabled(!projects.contains { hidden.contains($0.id) })
                Button(.projectsDeselectAll) { send(.allProjectsVisibilityChanged(isVisible: false)) }
                    .disabled(!projects.contains { !hidden.contains($0.id) })
            }
            .disabled(!store.canChangeAccount)
            List(matches) { project in
                Toggle(isOn: Binding(
                    get: { !hidden.contains(project.id) },
                    set: { send(.projectVisibilityChanged(project.id, isVisible: $0)) }
                )) {
                    ProjectLabel(project: project)
                }
                .toggleStyle(.checkbox)
                .disabled(!store.canChangeAccount)
            }
            .listStyle(.inset)
            .overlay {
                if matches.isEmpty {
                    Text(.projectsNoMatches).foregroundStyle(.secondary)
                }
            }
            HStack {
                Spacer()
                Button(.projectsDone) { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460, height: 440)
        .onExitCommand { dismiss() }
    }
}
