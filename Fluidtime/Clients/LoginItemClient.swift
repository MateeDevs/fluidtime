import ComposableArchitecture

@DependencyClient
struct LoginItemClient: Sendable {
    var status: @MainActor @Sendable () -> LaunchAtLoginStatus = { .disabled }
    var setEnabled: @MainActor @Sendable (Bool) throws -> Void
    var openSettings: @MainActor @Sendable () -> Void
}

extension LoginItemClient: TestDependencyKey {
    static let testValue = Self()
    static let previewValue = Self(status: { .disabled }, setEnabled: { _ in }, openSettings: {})
}

extension DependencyValues {
    var loginItem: LoginItemClient {
        get { self[LoginItemClient.self] }
        set { self[LoginItemClient.self] = newValue }
    }
}
