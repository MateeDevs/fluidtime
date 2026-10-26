import Foundation

/// Account operations are scoped to the specified Keychain service.
struct KeychainItemStore {
    let service: String
    let accessibility: KeychainStorage.Accessibility
    var storage = KeychainStorage.live

    func read<Value>(account: String, decode: (Data) -> Value?) throws -> Value? {
        guard let data = try storage.read(service, account) else { return nil }
        guard let value = decode(data) else { throw KeychainStorage.Failure.invalidData }
        return value
    }

    func save(_ data: Data, account: String) throws {
        try storage.save(service, account, data, accessibility)
    }

    func delete(account: String) throws {
        try storage.delete(service, account)
    }
}
