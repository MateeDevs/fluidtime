import AppKit
import ComposableArchitecture
@testable import FluidtimeCore
import SwiftUI

struct ReviewPreviewCase {
    enum Screen { case menu, main, settings(Int), settingsContent(Int), projectVisibility, generalSettingsContent,
                       menuBarSettingsContent, editor, label,
                       feedback(TimerFeedback)
    }

    let name: String
    let screen: Screen
    var state: AppFeature.State
    var size: NSSize
    var dark = false
    var scroll: CGFloat = 0
    var increasedContrast = false
    var rightToLeft = false
    var editor: EntryEditorFeature.State?

    init(_ name: String, _ screen: Screen, state: AppFeature.State) {
        self.name = name
        self.screen = screen
        self.state = state
        switch screen {
        case .menu: size = NSSize(width: 380, height: state.isConnected ? 620 : (state.error == nil ? 290 : 420))
        case .main: size = NSSize(width: 1040, height: 760)
        case .settings, .settingsContent, .projectVisibility, .generalSettingsContent,
             .menuBarSettingsContent: size = NSSize(
                width: 540,
                height: 460
            )
        case .editor: size = NSSize(width: 460, height: 440)
        case .label: size = NSSize(width: 200, height: 32)
        case .feedback: size = NSSize(width: 240, height: 56)
        }
    }

    @MainActor
    private func settingsContent(_ index: Int, store: StoreOf<AppFeature>) -> AnyView {
        switch index {
        case 0: AnyView(AccountSettingsView(store: store))
        case 1: AnyView(TrackingSettingsView(store: store))
        case 2: AnyView(MenuBarSettingsView(store: store))
        case 3: AnyView(GeneralSettingsView(store: store.scope(state: \.generalSettings, action: \.generalSettings)))
        case 4: AnyView(WorkspaceSettingsView(store: store))
        default: AnyView(EarningsSettingsView(store: store))
        }
    }

    @MainActor
    var view: AnyView {
        let store = Store(initialState: state) { ReviewPreviewReducer() }
        let content = switch screen {
        case .menu: AnyView(MenuBarView(store: store))
        case .main: AnyView(MainWindowView(store: store))
        case let .settings(index): AnyView(ReviewSettingsTabs(store: store, selection: index))
        case let .settingsContent(index): settingsContent(index, store: store)
        case .projectVisibility: AnyView(ProjectVisibilityList(store: store))
        case .generalSettingsContent:
            AnyView(GeneralSettingsView(
                store: store.scope(state: \.generalSettings, action: \.generalSettings)
            ))
        case .menuBarSettingsContent:
            AnyView(MenuBarSettingsView(store: store))
        case .label: AnyView(MenuBarLabelView(store: store))
        case .editor:
            AnyView(EntryEditorView(store: Store(initialState: editor!) {
                BindingReducer<EntryEditorFeature.State, EntryEditorFeature.Action,
                    EntryEditorFeature.Action.View>(action: \.view)
            }))
        case let .feedback(feedback): AnyView(TimerFeedbackView(feedback: feedback))
        }
        return AnyView(content
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.calendar, state.user?.calendar ?? .current)
            .environment(\.timeZone, state.user?.calendar.timeZone ?? .current)
            .environment(\.locale, Locale(identifier:
                ProcessInfo.processInfo.environment["FLUIDTIME_PREVIEW_LANGUAGE"] ?? Locale.current.identifier))
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.layoutDirection, rightToLeft ? .rightToLeft : .leftToRight))
    }
}
