import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

struct KeychainItemStoreTests {
    @Test func `reads use only the configured service`() throws {
        let reads = LockIsolated<[String]>([])
        let storage = KeychainStorage(
            read: { service, _ in
                reads.withValue { $0.append(service) }
                return nil
            }, save: { _, _, _, _ in Issue.record("A normal read must not write") },
            delete: { _, _ in Issue.record("A normal read must not delete") }
        )
        let store = KeychainItemStore(service: "current", accessibility: .credentials, storage: storage)
        let value = try store.read(account: "account") { String(data: $0, encoding: .utf8) }
        #expect(value == nil)
        #expect(reads.value == ["current"])
    }

    @Test func `normal writes and disconnect touch only the current installation`() throws {
        let operations = LockIsolated<[String]>([])
        let storage = KeychainStorage(
            read: { _, _ in nil },
            save: { service, account, _, _ in operations.withValue { $0.append("save:\(service):\(account)") } },
            delete: { service, account in operations.withValue { $0.append("delete:\(service):\(account)") } }
        )
        let store = KeychainItemStore(service: "current", accessibility: .credentials, storage: storage)
        try store.save(Data("fictional-token".utf8), account: "account")
        try store.delete(account: "account")
        #expect(operations.value == ["save:current:account", "delete:current:account"])
    }
}
