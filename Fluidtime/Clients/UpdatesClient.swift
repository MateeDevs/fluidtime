import ComposableArchitecture

struct UpdateStatus: Equatable, Sendable {
    var isAvailable = false
    var canCheck = false
    var automaticallyChecks = false
    var automaticallyInstalls = false
}

@DependencyClient
struct UpdatesClient: Sendable {
    var start: @MainActor @Sendable () -> Void
    var statuses: @MainActor @Sendable () -> AsyncStream<UpdateStatus> = { .finished }
    var check: @MainActor @Sendable () -> Void
    var setAutomaticChecks: @MainActor @Sendable (Bool) -> Void
    var setAutomaticInstallation: @MainActor @Sendable (Bool) -> Void
}

extension UpdatesClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var updates: UpdatesClient {
        get { self[UpdatesClient.self] }
        set { self[UpdatesClient.self] = newValue }
    }
}
