import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
struct MainWindowView: View {
    @Bindable var store: StoreOf<AppFeature>
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 900
            content(isCompact: isCompact)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    if store.isConnected {
                        ToolbarItem(placement: .principal) {
                            WorkspaceNavigationControl(store: store.scope(state: \.workspace, action: \.workspace),
                                                       isCompact: isCompact)
                                .disabled(store.isBusy || store.destination != nil)
                        }
                    }
                    if isCompact {
                        ToolbarItem { actionsMenu }
                    } else {
                        ToolbarItemGroup {
                            refreshButton
                            if store.isConnected {
                                exportButton.labelStyle(.iconOnly)
                            }
                        }
                        ToolbarItemGroup {
                            websiteButton.labelStyle(.iconOnly)
                            settingsButton.labelStyle(.iconOnly)
                        }
                    }
                }
        }
        .confirmationDialog($store.scope(state: \.destination?.deleteEntry, action: \.destination.deleteEntry))
        .focusedValue(\.workspaceStore, store)
        .frame(minWidth: 320, minHeight: 320)
        .environment(\.calendar, store.user?.calendar ?? .current)
        .environment(\.timeZone, store.user?.calendar.timeZone ?? .current)
    }

    @ViewBuilder
    private func content(isCompact: Bool) -> some View {
        if store.isConnected {
            WorkspaceView(
                store: store.scope(state: \.workspace, action: \.workspace),
                earnings: store.scope(state: \.earnings, action: \.earnings),
                data: store.data,
                preferences: store.preferences.workspace, scope: store.accountScope,
                isBusy: store.isBusy || store.destination != nil, isCompact: isCompact
            ) {
                timerHeader
            } footer: {
                errorBanner
            }
        } else if store.isLoadingAccount {
            AccountLoadingView(showsProgress: store.showsProgress)
        } else if store.isConfigured || store.error != nil {
            accountUnavailable
        } else {
            ContentUnavailableView {
                Label(.connectToSolidtime, systemImage: "clock")
            } description: {
                Text(.connectYourSolidtimeAccountToTrackTimeFromTheMenuBar)
            } actions: {
                Button(.settings) { showSettings() }.buttonStyle(.borderedProminent)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { errorBanner }
        }
    }

    private var actionsMenu: some View {
        Menu {
            Button { send(.refreshTapped) } label: { Label(.refreshTimeEntries, systemImage: "arrow.clockwise") }
                .labelStyle(.titleAndIcon)
                .disabled(store.isBusy || !store.isConfigured || store.destination != nil)
            if store.isConnected {
                exportButton.labelStyle(.titleAndIcon)
            }
            Divider()
            websiteButton.labelStyle(.titleAndIcon)
            settingsButton.labelStyle(.titleAndIcon)
        } label: {
            Label(.windowActions, systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
        .help(.windowActions)
        .accessibilityLabel(.windowActions)
    }

    private var exportButton: some View {
        WorkspaceExportButton(store: store.scope(state: \.workspace, action: \.workspace), data: store.data,
                              lunchWindow: store.preferences.workspace.lunchWindow,
                              isBusy: store.isBusy || store.destination != nil)
    }

    private var websiteButton: some View {
        Button { send(.openInstanceTapped) } label: { Label(.openSolidtime, systemImage: "arrow.up.right.square") }
            .help(.openSolidtime).accessibilityLabel(.openSolidtime)
    }

    private var settingsButton: some View {
        Button { showSettings() } label: { Label(.settings, systemImage: "gearshape") }
            .help(.settings).accessibilityLabel(.settings)
    }

    private var refreshButton: some View {
        Button { send(.refreshTapped) } label: {
            ZStack {
                Image(systemName: "arrow.clockwise").opacity(store.showsProgress ? 0 : 1)
                if store.showsProgress {
                    ProgressView().controlSize(.small).frame(width: 16, height: 16)
                }
            }
            .frame(width: 24, height: 24)
        }
        .help(.refreshTimeEntries)
        .accessibilityLabel(store.showsProgress ? .updatingSolidtime : .refreshTimeEntries)
        .disabled(store.isBusy || !store.isConfigured || store.destination != nil)
    }

    private var accountUnavailable: some View {
        ContentUnavailableView {
            Label(.accountUnavailable, systemImage: "exclamationmark.triangle")
        } description: {
            Text(.accountUnavailableHelp)
        } actions: {
            if store.isConfigured {
                Button(.refreshTimeEntries) { send(.refreshTapped) }.disabled(store.isBusy)
            }
            Button(.settings) { showSettings() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { errorBanner }
    }

    private var timerHeader: some View {
        VStack(spacing: 0) {
            MainTimerControls(store: store)
            if let reminder = store.reminder {
                HStack {
                    Label(reminder.message, systemImage: "clock.badge.exclamationmark")
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button(.stopTimer) { send(.stopTapped) }.disabled(store.isBusy || store.destination != nil)
                    Button(.reminderDismiss) { send(.dismissReminder) }
                }.padding(12).background(.quaternary)
            }
            Divider()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = store.error {
            HStack {
                Label(error, systemImage: "exclamationmark.triangle")
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(.refreshTimeEntries) { send(.refreshTapped) }
                    .disabled(store.isBusy || !store.isConfigured || store.destination != nil)
            }.font(.callout).padding(12).background(.quaternary)
        }
    }

    private func showSettings() {
        openSettings()
        NSApplication.shared.activate(ignoringOtherApps: true)
        send(.settingsOpened)
    }
}
