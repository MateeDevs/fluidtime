import ComposableArchitecture
import ServiceManagement

extension LoginItemClient: DependencyKey {
    static let liveValue = Self(
        status: { currentStatus() },
        setEnabled: { enabled in
            guard currentStatus().isRegistered != enabled else { return }
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        },
        openSettings: { SMAppService.openSystemSettingsLoginItems() }
    )

    @MainActor
    private static func currentStatus() -> LaunchAtLoginStatus {
        LaunchAtLoginStatus(serviceStatus: SMAppService.mainApp.status)
    }
}

extension LaunchAtLoginStatus {
    init(serviceStatus: SMAppService.Status) {
        switch serviceStatus {
        case .notRegistered, .notFound: self = .disabled
        case .enabled: self = .enabled
        case .requiresApproval: self = .requiresApproval
        @unknown default: self = .unavailable
        }
    }
}
