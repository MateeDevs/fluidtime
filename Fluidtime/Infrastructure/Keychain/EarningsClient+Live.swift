import ComposableArchitecture
import Foundation

extension EarningsClient: DependencyKey {
    static let liveValue = Self(load: { try EarningsStore.load($0) }, save: { try EarningsStore.save($1, scope: $0) })
}

private enum EarningsStore {
    private static func store() -> KeychainItemStore {
        KeychainItemStore(
            service: "cz.matee.fluidtime.earnings",
            accessibility: .privateValues
        )
    }

    /// The feature calls this only after fresh biometric authentication.
    static func load(_ scope: String) throws -> EarningsSettings {
        do {
            return try store().read(account: scope) { try? JSONDecoder().decode(EarningsSettings.self, from: $0) }
                ?? EarningsSettings()
        } catch { throw AppError.message(String(localized: .earningsReadFailed)) }
    }

    static func save(_ settings: EarningsSettings, scope: String) throws {
        do {
            try store().save(JSONEncoder().encode(settings), account: scope)
        } catch { throw AppError.message(String(localized: .earningsSaveFailed)) }
    }
}
