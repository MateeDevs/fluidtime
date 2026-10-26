import ComposableArchitecture
import Foundation

extension AppFeature {
    func handleInterface(_ action: Action.Interface, state: inout State) -> Effect<Action> {
        switch action {
        case .start:
            return startLifecycle(&state)
        case .shutdown:
            return shutdown(&state)
        case .toggleMenuBar:
            guard state.destination?.editor?.isSaving != true else { return .none }
            state.isMenuBarPresented.toggle()
            return .none
        case .toggleTimer:
            if !state.isConnected || state.data.membership == nil || state.lastSynced == nil {
                return .run { [system] _ in await system.openMainWindow() }
            }
            return toggleTimer(&state)
        case .openPrimaryInterface:
            return .run { [system] _ in await system.openMainWindow() }
        case let .menuBarPresentationChanged(isPresented):
            return handleMenuBarPresentation(isPresented, state: &state)
        case .settingsWindowOpenChanged, .mainWindowOpenChanged, .editorPresentationChanged:
            return handleWindowEvent(action, state: &state)
        }
    }

    private func handleMenuBarPresentation(_ isPresented: Bool, state: inout State) -> Effect<Action> {
        guard isPresented || state.destination?.editor?.isSaving != true else { return .none }
        state.isMenuBarPresented = isPresented
        if !isPresented, state.destination?.editor?.presentationAnchor?.hasPrefix("tracker.panel.") == true {
            return .run { [system] _ in await system.closeEntryEditor() }
        }
        return .none
    }

    private func handleWindowEvent(_ action: Action.Interface, state: inout State) -> Effect<Action> {
        switch action {
        case let .settingsWindowOpenChanged(isOpen):
            guard state.isSettingsWindowOpen != isOpen else { return .none }
            state.isSettingsWindowOpen = isOpen
            let showDock = state.showsDockIcon
            let hasPrivateValues = state.earnings.surface == .settings || state.earnings.pendingSurface == .settings
            let privacy: Effect<Action> = !isOpen && hasPrivateValues
                ? .send(.earnings(.interface(.conceal(.settings)))) : .none
            return .merge(privacy, .run { [system] _ in await system.setDockIconVisible(showDock) })
        case let .mainWindowOpenChanged(isOpen):
            guard state.isMainWindowOpen != isOpen else { return .none }
            state.isMainWindowOpen = isOpen
            let showDock = state.showsDockIcon
            let hasPrivateValues = state.earnings.surface == .preview || state.earnings.pendingSurface == .preview
            let privacy: Effect<Action> = !isOpen && hasPrivateValues
                ? .send(.earnings(.interface(.conceal(.preview)))) : .none
            return .merge(privacy, .run { [system] _ in await system.setDockIconVisible(showDock) })
        case let .editorPresentationChanged(isOpen):
            state.isEditorPresented = isOpen
            return !isOpen && state.destination?.editor != nil ? .send(.destination(.dismiss)) : .none
        default: return .none
        }
    }

    private func startLifecycle(_ state: inout State) -> Effect<Action> {
        guard state.lifecycle == .stopped else { return .none }
        let id = uuid()
        state.lifecycle = .restoring(id)
        return .merge(
            .run { [credentials, preferences] send in
                let saved = preferences.load()
                do {
                    let url = try Connection(instance: saved.instance, token: "lookup").instance
                    let token = try credentials.read(url)
                    try Task.checkCancellation()
                    let connection = try token.map { try Connection(instance: saved.instance, token: $0) }
                    await send(.restored(id, saved, .success(connection)))
                } catch {
                    guard !Task.isCancelled else { return }
                    await send(.restored(id, saved, .failure(Failure(error))))
                }
            },
            .run { [clock] send in
                for await _ in clock.timer(interval: .seconds(30)) {
                    try Task.checkCancellation()
                    await send(.refreshRequested(full: false))
                }
            }
        )
        .cancellable(id: CancelID.lifecycle, cancelInFlight: true)
    }
}
