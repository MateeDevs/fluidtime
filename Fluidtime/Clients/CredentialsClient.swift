import ComposableArchitecture
import Foundation

@DependencyClient
struct CredentialsClient: Sendable {
    var read: @Sendable (URL) throws -> String?
    var save: @Sendable (Connection) throws -> Void
    var delete: @Sendable (URL) throws -> Void
}

extension CredentialsClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var credentials: CredentialsClient {
        get { self[CredentialsClient.self] }
        set { self[CredentialsClient.self] = newValue }
    }
}
