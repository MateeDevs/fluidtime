#if FLUIDTIME_ALPHA || DEBUG || SWIFT_PACKAGE
    import ComposableArchitecture
    import Foundation

    /// Overrides service boundaries while keeping the real reducers and native window behavior.
    struct AlphaEnvironment: Sendable {
        let session: AlphaSession
        let connection: Connection
        private let savedConnection: LockIsolated<Connection?>
        private let savedPreferences: LockIsolated<AppPreferences>
        private let rates = LockIsolated<[String: EarningsSettings]>([:])
        private let loginEnabled = LockIsolated(false)

        init(now: Date = .now) throws {
            let connection = try Connection(instance: AlphaSampleData.instanceAddress, token: AlphaSampleData.token)
            self.connection = connection
            session = AlphaSession(sample: AlphaSampleData(now: now))
            savedConnection = LockIsolated(connection)
            var preferences = AppPreferences()
            preferences.instance = AlphaSampleData.instanceAddress
            preferences.membershipId = AlphaSampleData.memberships[0].id
            preferences.workspace.earningsEnabled = true
            let initialPreferences = preferences
            savedPreferences = LockIsolated(initialPreferences)
        }

        func configure(_ dependencies: inout DependencyValues) {
            dependencies.solidtime = solidtime
            dependencies.preferences = preferences
            dependencies.credentials = CredentialsClient(
                read: { url in savedConnection.value.flatMap { $0.instance == url ? $0.token : nil } },
                save: { savedConnection.setValue($0) }, delete: { _ in savedConnection.setValue(nil) }
            )
            dependencies.earnings = EarningsClient(
                load: { rates.value[$0] ?? EarningsSettings(currency: "USD", hourlyRate: 25) },
                save: { scope, settings in rates.withValue { $0[scope] = settings } }
            )
            dependencies.biometrics = BiometricsClient(authenticate: { true })
            dependencies.loginItem = LoginItemClient(
                status: { loginEnabled.value ? .enabled : .disabled },
                setEnabled: { loginEnabled.setValue($0) }, openSettings: {}
            )
            dependencies.updates = UpdatesClient(
                start: {}, statuses: { AsyncStream { $0.yield(UpdateStatus()); $0.finish() } },
                check: {}, setAutomaticChecks: { _ in }, setAutomaticInstallation: { _ in }
            )
            var system = SystemClient.liveValue
            system.openURL = { _ in }
            system.idleSeconds = { 0 }
            dependencies.system = system
        }

        private var solidtime: SolidtimeClient {
            SolidtimeClient(
                user: { try await session.user($0) },
                memberships: { try await session.memberships($0) },
                activeEntry: { try await session.activeEntry($0) },
                projects: { try await session.projects($0, organization: $1) },
                entries: { try await session.history($0, membership: $1, since: $2) },
                create: { try await session.create($0, membership: $1, description: $2, project: $3, at: $4) },
                delete: { try await session.delete($0, entry: $1) },
                update: { try await session.update($0, update: $1) }
            )
        }

        private var preferences: PreferencesClient {
            PreferencesClient(
                load: { savedPreferences.value },
                setInstance: { value in savedPreferences.withValue { $0.instance = value } },
                setMembership: { value in savedPreferences.withValue { $0.membershipId = value } },
                setMenuBarUsesProjectColor: { value in
                    savedPreferences.withValue { $0.menuBarUsesProjectColor = value }
                },
                setMenuBarShowsSeconds: { value in savedPreferences.withValue { $0.menuBarShowsSeconds = value } },
                setMenuBarDisplay: { value in savedPreferences.withValue { $0.menuBarDisplay = value } },
                setWorkspace: { value in savedPreferences.withValue { $0.workspace = value } },
                setProjectVisibility: { value in savedPreferences.withValue { $0.projectVisibility = value } }
            )
        }
    }
#endif
