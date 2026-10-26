import Foundation
import Security

struct KeychainStorage: Sendable {
    enum Accessibility: Sendable {
        case credentials, privateValues
    }

    enum Failure: Error {
        case read, save, update, delete, invalidData
    }

    var read: @Sendable (String, String) throws -> Data?
    var save: @Sendable (String, String, Data, Accessibility) throws -> Void
    var delete: @Sendable (String, String) throws -> Void

    static let live = Self(
        read: { service, account in
            var query = query(service: service, account: account)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecItemNotFound {
                return nil
            }
            guard status == errSecSuccess, let data = result as? Data else { throw Failure.read }
            return data
        },
        save: { service, account, data, accessibility in
            var attributes = query(service: service, account: account)
            let status = SecItemUpdate(attributes as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            if status == errSecItemNotFound {
                attributes[kSecValueData as String] = data
                attributes[kSecAttrAccessible as String] = accessibility == .credentials
                    ? kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                guard SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess else { throw Failure.save }
            } else if status != errSecSuccess {
                throw Failure.update
            }
        },
        delete: { service, account in
            let status = SecItemDelete(query(service: service, account: account) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw Failure.delete }
        }
    )

    private static func query(service: String, account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
