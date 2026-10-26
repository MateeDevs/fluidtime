import ComposableArchitecture

@DependencyClient
struct BiometricsClient: Sendable {
    var authenticate: @MainActor @Sendable () async throws -> Bool
}

extension BiometricsClient: TestDependencyKey {
    static let testValue = Self()
}

extension DependencyValues {
    var biometrics: BiometricsClient {
        get { self[BiometricsClient.self] }
        set { self[BiometricsClient.self] = newValue }
    }
}
