import ComposableArchitecture
import Foundation

extension SolidtimeClient: DependencyKey {
    static let liveValue = Self.live(
        session: URLSession(configuration: .ephemeral, delegate: NoRedirectDelegate(), delegateQueue: nil)
    )

    static func live(session: URLSession) -> Self {
        Self(
            user: { try await SolidtimeAPI(connection: $0, session: session).user() },
            memberships: { try await SolidtimeAPI(connection: $0, session: session).memberships() },
            activeEntry: { try await SolidtimeAPI(connection: $0, session: session).activeEntry() },
            projects: { try await SolidtimeAPI(connection: $0, session: session).projects(organization: $1) },
            entries: { try await SolidtimeAPI(connection: $0, session: session).entries(membership: $1, since: $2) },
            create: {
                try await SolidtimeAPI(connection: $0, session: session).create(
                    membership: $1, description: $2, project: $3, at: $4
                )
            },
            delete: { try await SolidtimeAPI(connection: $0, session: session).delete($1) },
            update: { connection, update in
                try await SolidtimeAPI(connection: connection, session: session).update(
                    update.entry, memberId: update.memberId, changes: update.body
                )
            }
        )
    }
}
