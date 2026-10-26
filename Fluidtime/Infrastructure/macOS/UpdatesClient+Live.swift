import ComposableArchitecture
import Foundation
import Sparkle

extension UpdatesClient: DependencyKey {
    static let liveValue: Self = {
        guard UpdatesConfiguration.isEnabled else { return unavailable }
        return Self(
            start: { SparkleUpdates.shared.start() },
            statuses: { SparkleUpdates.shared.statuses() },
            check: { SparkleUpdates.shared.check() },
            setAutomaticChecks: { SparkleUpdates.shared.setAutomaticChecks($0) },
            setAutomaticInstallation: { SparkleUpdates.shared.setAutomaticInstallation($0) }
        )
    }()

    private static let unavailable = Self(
        start: {},
        statuses: {
            AsyncStream { continuation in
                continuation.yield(UpdateStatus())
                continuation.finish()
            }
        },
        check: {},
        setAutomaticChecks: { _ in },
        setAutomaticInstallation: { _ in }
    )
}

@MainActor
private final class SparkleUpdates {
    static let shared = SparkleUpdates()
    private let controller = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    private var started = false
    private var observations: [UUID: [NSKeyValueObservation]] = [:]

    private var isConfigured: Bool {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
              Data(base64Encoded: key)?.count == 32,
              let address = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
              let url = URL(string: address), url.scheme == "https", url.host != nil else { return false }
        return true
    }

    private var status: UpdateStatus {
        UpdateStatus(isAvailable: isConfigured, canCheck: started && controller.updater.canCheckForUpdates,
                     automaticallyChecks: controller.updater.automaticallyChecksForUpdates,
                     automaticallyInstalls: controller.updater.automaticallyDownloadsUpdates)
    }

    func start() {
        guard !started, isConfigured else { return }
        started = true
        controller.startUpdater()
    }

    func check() {
        guard status.canCheck else { return }
        controller.checkForUpdates(nil)
    }

    func setAutomaticChecks(_ value: Bool) {
        controller.updater.automaticallyChecksForUpdates = value
    }

    func setAutomaticInstallation(_ value: Bool) {
        controller.updater.automaticallyDownloadsUpdates = value
    }

    func statuses() -> AsyncStream<UpdateStatus> {
        let id = UUID()
        return AsyncStream { continuation in
            continuation.yield(status)
            let updater = controller.updater
            let emit: @MainActor @Sendable () -> Void = { [weak self] in
                if let self {
                    continuation.yield(status)
                }
            }
            observations[id] = [
                updater.observe(\.canCheckForUpdates) { _, _ in MainActor.assumeIsolated { emit() } },
                updater.observe(\.automaticallyChecksForUpdates) { _, _ in MainActor.assumeIsolated { emit() } },
                updater.observe(\.automaticallyDownloadsUpdates) { _, _ in MainActor.assumeIsolated { emit() } }
            ]
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in _ = self?.observations.removeValue(forKey: id) }
            }
        }
    }
}
