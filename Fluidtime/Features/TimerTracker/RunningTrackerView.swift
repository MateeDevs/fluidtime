import ComposableArchitecture
import SwiftUI

struct RunningTrackerView: View {
    let store: StoreOf<AppFeature>
    let entry: TimeEntry
    let style: TimerTrackerView.Style

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if style == .window {
                ViewThatFits(in: .horizontal) {
                    wideLayout.frame(minWidth: 560)
                    compactLayout
                }
            } else {
                compactLayout
            }
            if store.activeInAnotherOrganization {
                Text(.yourTimerIsRunningInAnotherOrganizationStopItHereOrSelectItsOrganizationToEditIt)
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var wideLayout: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                TrackerElapsedTime(entry: entry)
                TrackerStatus(isRunning: true)
            }
            context.frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 10) {
                TrackerPrimaryButton(store: store)
                editingControls
            }
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TrackerStatus(isRunning: true)
                Spacer()
                editingControls
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    TrackerElapsedTime(entry: entry)
                    Spacer(minLength: 0)
                    TrackerPrimaryButton(store: store)
                }
                VStack(alignment: .leading, spacing: 10) {
                    TrackerElapsedTime(entry: entry)
                    TrackerPrimaryButton(store: store)
                }
            }
            context
        }
    }

    private var context: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title).font(.headline).lineLimit(2).textSelection(.enabled).help(entry.title)
            if store.activeInAnotherOrganization {
                Text(.timerOtherOrganization).font(.callout).foregroundStyle(.secondary)
            } else {
                ProjectLabel(project: store.data.projects.first { $0.id == entry.projectId },
                             fallback: entry.projectId == nil ? .noProject : .unavailableProject)
                    .font(.callout).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var editingControls: some View {
        if !store.activeInAnotherOrganization {
            TrackerEditingControls(store: store, entry: entry, style: style)
        }
    }
}
