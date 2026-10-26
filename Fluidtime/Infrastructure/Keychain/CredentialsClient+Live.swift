import ComposableArchitecture

extension CredentialsClient: DependencyKey {
    static let liveValue = Self(
        read: { try CredentialStore.read(for: $0) },
        save: { try CredentialStore.save($0.token, for: $0.instance) },
        delete: { try CredentialStore.delete(for: $0) }
    )
}
