import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct ReadyTrackerView: View {
    @Bindable var store: StoreOf<AppFeature>
    let style: TimerTrackerView.Style

    var body: some View {
        if style == .window {
            windowLayout
        } else {
            VStack(alignment: .leading, spacing: 12) {
                TrackerStatus(isRunning: false)
                compactLayout
            }
        }
    }

    private var windowLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(.newTimer, systemImage: "timer").font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                Text(.description).font(.caption).foregroundStyle(.secondary)
                descriptionField
            }
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(.project).font(.caption).foregroundStyle(.secondary)
                    ProjectPicker(projects: store.selectableProjects, selected: $store.projectId,
                                  currentProject: store.data.projects.first { $0.id == store.projectId },
                                  showsLabel: false)
                }
                TrackerPrimaryButton(store: store, showsFullTitle: true)
            }
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            descriptionField
            HStack(spacing: 12) {
                ProjectPicker(projects: store.selectableProjects, selected: $store.projectId,
                              currentProject: store.data.projects.first { $0.id == store.projectId })
                TrackerPrimaryButton(store: store)
            }
        }
    }

    private var descriptionField: some View {
        TextField(String(localized: .whatAreYouWorkingOn), text: $store.description)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel(.description)
    }
}
