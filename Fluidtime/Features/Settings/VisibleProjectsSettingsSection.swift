import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct VisibleProjectsSettingsSection: View {
    let store: StoreOf<AppFeature>
    @State private var isPresented = false

    var body: some View {
        Section {
            Text(.projectsVisibilityHelp).font(.callout).foregroundStyle(.secondary)
            if store.availableProjects.isEmpty {
                Text(.projectsVisibilityEmpty).foregroundStyle(.secondary)
            } else {
                Button(.projectsManage) { isPresented = true }
                    .disabled(!store.canChangeAccount)
                    .sheet(isPresented: $isPresented) {
                        ProjectVisibilityList(store: store)
                    }
            }
        } header: {
            Text(.projectsVisibilityTitle)
        }
    }
}
