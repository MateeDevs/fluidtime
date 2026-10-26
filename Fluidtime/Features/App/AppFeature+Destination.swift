import ComposableArchitecture
import Foundation

extension AppFeature {
    @Reducer
    enum Destination {
        case editor(EntryEditorFeature)
        case disconnect(ConfirmationDialogState<Disconnect>)
        case deleteEntry(ConfirmationDialogState<DeleteEntry>)
    }

    static func disconnectConfirmation() -> ConfirmationDialogState<Destination.Disconnect> {
        ConfirmationDialogState(titleVisibility: .visible) {
            TextState(.disconnectFromSolidtime)
        } actions: {
            ButtonState(role: .destructive, action: .confirm) { TextState(.disconnect) }
            ButtonState(role: .cancel) { TextState(.cancel) }
        } message: {
            TextState(
                .yourApiKeyWillBeRemovedFromThisMacAnyRunningTimerWillKeepRunningOnSolidtime
            )
        }
    }
}

extension AppFeature.Destination.State: Equatable {}
extension AppFeature.Destination.Action: Equatable {}

extension AppFeature.Destination {
    enum Disconnect: Equatable { case confirm }
    enum DeleteEntry: Equatable { case confirm(TimeEntry) }
}
