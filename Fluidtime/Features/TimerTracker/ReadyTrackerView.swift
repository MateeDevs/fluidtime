import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct ReadyTrackerView: View {
    @Bindable var store: StoreOf<AppFeature>
    let style: TimerTrackerView.Style

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TrackerStatus(isRunning: false)
            if style == .window {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) {
                        inputs
                        TrackerPrimaryButton(store: store)
                    }.frame(minWidth: 560)
                    compactLayout
                }
            } else {
                compactLayout
            }
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            descriptionField
            HStack(spacing: 12) {
                projectPicker
                TrackerPrimaryButton(store: store)
            }
        }
    }

    private var inputs: some View {
        VStack(alignment: .leading, spacing: 8) {
            descriptionField
            projectPicker.frame(maxWidth: 300)
        }
    }

    private var descriptionField: some View {
        TextField(String(localized: .whatAreYouWorkingOn), text: $store.description)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel(.description)
    }

    private var projectPicker: some View {
        ProjectPicker(projects: store.selectableProjects, selected: $store.projectId,
                      currentProject: store.data.projects.first { $0.id == store.projectId })
    }
}
