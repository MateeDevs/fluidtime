import Foundation

enum CredentialStore {
    private static func store() -> KeychainItemStore {
        KeychainItemStore(
            service: "cz.matee.fluidtime.solidtime",
            accessibility: .credentials
        )
    }

    static func read(for instance: URL) throws -> String? {
        do {
            return try store().read(account: instance.absoluteString) { String(data: $0, encoding: .utf8) }
        } catch {
            throw AppError.message(String(localized: .couldntReadYourApiKeyFromKeychainEnterItAgainInSettings))
        }
    }

    static func save(_ token: String, for instance: URL) throws {
        do {
            try store().save(Data(token.utf8), account: instance.absoluteString)
        } catch KeychainStorage.Failure.update {
            throw AppError.message(String(localized: .couldntUpdateYourApiKeyInKeychain))
        } catch {
            throw AppError.message(String(localized: .couldntSaveYourApiKeyInKeychain))
        }
    }

    static func delete(for instance: URL) throws {
        do {
            try store().delete(account: instance.absoluteString)
        } catch {
            throw AppError.message(String(localized: .couldntRemoveYourApiKeyFromKeychain))
        }
    }
}
