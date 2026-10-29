import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct MenuBarView: View {
    @Bindable var store: StoreOf<AppFeature>
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if store.isConnected {
                TimerTrackerView(store: store, style: .panel)
                    .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
                totals.padding(.horizontal, 16).padding(.bottom, 12)
                Divider()
            }
            errorBanner
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if store.isLoadingAccount {
                        AccountLoadingView(showsProgress: store.showsProgress)
                    } else if !store.isConnected, store.isConfigured || store.error != nil {
                        Text(.accountUnavailable).font(.headline)
                    } else if !store.isConnected {
                        welcome
                    } else {
                        if !store.pinnedPresets.isEmpty {
                            PinnedTasksView(store: store)
                        }
                        recent
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: .infinity)
            Divider()
            footer
        }
        .frame(width: 380, height: store.isConnected ? 620 : (store.error == nil ? 290 : 420))
    }

    private var header: some View {
        HStack {
            Label(.fluidtime, systemImage: "clock")
                .font(.headline)
            Spacer()
            if store.showsProgress {
                ProgressView().controlSize(.small).accessibilityLabel(.updatingSolidtime)
            }
            Button {
                send(.refreshTapped)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help(.refreshTimeEntries)
            .accessibilityLabel(.refreshTimeEntries)
            .disabled(store.isBusy || !store.isConfigured)
            Button {
                showSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .help(.settings)
            .accessibilityLabel(.settings)
        }
        .buttonStyle(.borderless)
        .padding(16)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.trackTimeFromYourMenuBar).font(.title2).fontWeight(.semibold)
            Text(.connectYourSolidtimeAccountToTrackTimeFromTheMenuBar)
                .foregroundStyle(.secondary)
            Button(.connectToSolidtime) { showSettings() }
                .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 16)
    }

    private var totals: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let totals = store.data.totals(at: context.date)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    totalCell(.today, value: totals.today)
                    WorkFinishCaption(data: store.data, targetHours: store.preferences.workspace.dailyGoalHours,
                                      tracked: totals.today, now: context.date)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                totalCell(.thisWeek, value: totals.week)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .help(
            .yourWorkTimeInTheSelectedOrganizationIncludingYourRunningTimerUsesYourSolidtimeTimeZoneAndWeekStart
        )
    }

    private func totalCell(_ title: LocalizedStringResource, value: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.callout).foregroundStyle(.secondary)
            Text(store.lastSynced == nil ? String(localized: .durationUnavailable) : TrackedTime.clock(value))
                .font(.title2.monospacedDigit()).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var recent: some View {
        let entries = store.recentEntries
        return VStack(alignment: .leading, spacing: 10) {
            Text(.recentEntries).font(.headline)
            if entries.isEmpty {
                Text(
                    store.lastSynced == nil
                        ? .yourRecentEntriesWillAppearHere
                        : .yourFinishedEntriesWillAppearHere
                )
                .font(.callout).foregroundStyle(.secondary)
            }
            ForEach(entries) { entry in
                let startLabel: LocalizedStringResource = store.active == nil
                    ? .startANewTimerFor(entry.title) : .stopTheCurrentTimerAndStartANewTimerFor(entry.title)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.title).lineLimit(2)
                        ProjectLabel(project: store.data.projects.first { $0.id == entry.projectId },
                                     fallback: entry.projectId == nil ? .noProject : .unavailableProject)
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Button {
                        send(.startRecent(entry))
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .help(startLabel)
                    .accessibilityLabel(startLabel)
                }
                .disabled(store.isBusy)
                if entry.id != entries.last?.id {
                    Divider()
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                send(.openMainWindow)
            } label: {
                Label(.workspaceOpenWindow, systemImage: "macwindow")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            HStack {
                Button {
                    send(.openInstanceTapped)
                } label: {
                    Label(.menuBarWebsite, systemImage: "arrow.up.right.square")
                }
                Spacer()
                Button(.menuBarQuit) { send(.quitTapped) }
                    .keyboardShortcut("q")
                    .help(.quitHelp)
                    .accessibilityHint(.quitHelp)
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
    }

    func showSettings() {
        openSettings()
        NSApplication.shared.activate(ignoringOtherApps: true)
        send(.settingsOpened)
    }
}
