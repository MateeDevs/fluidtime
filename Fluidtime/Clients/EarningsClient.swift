import ComposableArchitecture
import Foundation

@DependencyClient
struct EarningsClient: Sendable {
    var load: @Sendable (String) throws -> EarningsSettings
    var save: @Sendable (String, EarningsSettings) throws -> Void
}

extension EarningsClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var earnings: EarningsClient {
        get { self[EarningsClient.self] }
        set { self[EarningsClient.self] = newValue }
    }
}
