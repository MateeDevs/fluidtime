import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test(arguments: [true, false], [true, false])
    func `successful timer confirmations require the shortcut source`(shortcut: Bool, stopped: Bool) async {
        let saved = entry(end: stopped ? date : nil)
        var initial = state
        initial.workID = id
        initial.preferences.workspace.timerFeedback = true
        let feedback = LockIsolated<[TimerFeedback]>([])
        let store = TestStore(initialState: initial) { AppFeature() } withDependencies: {
            $0.date.now = date
            $0.system.showTimerFeedback = { value in feedback.withValue { $0.append(value) } }
        }
        let action: AppFeature.Action = shortcut
            ? .timerShortcutResponse(id, .success(.saved(saved)))
            : .mutationResponse(id, .success(.saved(saved)))
        await store.send(action) {
            $0.workID = nil
            $0.data.apply(saved, at: self.date)
        }
        await store.finish()
        let expected: TimerFeedback = stopped ? .stopped(saved) : .started(saved)
        #expect(feedback.value == (shortcut ? [expected] : []))
    }
}
