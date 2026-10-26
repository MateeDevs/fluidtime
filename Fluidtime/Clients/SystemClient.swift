import ComposableArchitecture
import Foundation

@DependencyClient
struct SystemClient: Sendable {
    var openURL: @MainActor @Sendable (URL) -> Void
    var quit: @MainActor @Sendable () -> Void
    var setDockIconVisible: @MainActor @Sendable (Bool) -> Void
    var openMainWindow: @MainActor @Sendable () -> Void
    var openEntryEditor: @MainActor @Sendable (String?) -> Void
    var closeEntryEditor: @MainActor @Sendable () -> Void
    var showTimerFeedback: @MainActor @Sendable (TimerFeedback) -> Void
    var idleSeconds: @Sendable () -> TimeInterval = { 0 }
    var exportCSV: @MainActor @Sendable (CSVDocument) async throws -> Bool
}

extension SystemClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var system: SystemClient {
        get { self[SystemClient.self] }
        set { self[SystemClient.self] = newValue }
    }
}
