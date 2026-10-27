import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

@MainActor
struct AlphaEnvironmentTests {
    @Test func `startup synchronization reads the shared fictional account`() async throws {
        let now = Date(timeIntervalSince1970: 1_792_620_000)
        let alpha = try AlphaEnvironment(now: now)
        let dependencies = clients(alpha)
        let preferences = dependencies.preferences.load()
        #expect(try dependencies.credentials.read(alpha.connection.instance) == AlphaSampleData.token)
        let snapshot = try await SessionSync(client: dependencies.solidtime).fetch(
            connection: alpha.connection, previous: SessionData(), preferredMembershipId: preferences.membershipId,
            full: true, now: now
        )
        #expect(snapshot.user == AlphaSampleData.user)
        #expect(snapshot.selectedMembershipId == "member")
        #expect(snapshot.entries.count == 106)
        #expect(snapshot.active?.id == "running")
        #expect(snapshot.projects == AlphaSampleData.projects)
    }

    @Test func `demo mutations update only the in memory session`() async throws {
        let now = Date(timeIntervalSince1970: 1_792_620_000)
        let alpha = try AlphaEnvironment(now: now)
        let membership = AlphaSampleData.memberships[0]
        let running = try #require(try await alpha.session.activeEntry(alpha.connection))
        let stopped = try await alpha.session.update(
            alpha.connection, update: EntryUpdate(entry: running, memberId: membership.id, change: .stop(now))
        )
        #expect(stopped.end == now)
        #expect(try await alpha.session.activeEntry(alpha.connection) == nil)
        let created = try await alpha.session.create(
            alpha.connection, membership: membership, description: "Alpha task", project: nil, at: now
        )
        var draft = EntryDraft(entry: created)
        draft.description = "Edited Alpha task"
        draft.projectId = AlphaSampleData.projects[0].id
        let edited = try await alpha.session.update(
            alpha.connection,
            update: EntryUpdate(entry: created, memberId: membership.id,
                                change: .edit(draft, AlphaSampleData.projects[0]))
        )
        #expect(edited.description == draft.description)
        #expect(edited.projectId == draft.projectId)
        #expect(edited.billable)
        try await alpha.session.delete(alpha.connection, entry: edited)
        #expect(try await alpha.session.activeEntry(alpha.connection) == nil)
        let history = try await alpha.session.history(alpha.connection, membership: membership, since: nil)
        #expect(!history.contains { $0.id == created.id })
        #expect(history.contains(stopped))
    }

    @Test func `demo services and preferences are isolated per environment`() async throws {
        let first = try AlphaEnvironment()
        let second = try AlphaEnvironment()
        let firstClients = clients(first)
        let secondClients = clients(second)
        firstClients.preferences.setMembership("other-member")
        #expect(firstClients.preferences.load().membershipId == "other-member")
        #expect(secondClients.preferences.load().membershipId == "member")
        try firstClients.earnings.save("scope", EarningsSettings(currency: "EUR", hourlyRate: 40))
        #expect(try firstClients.earnings.load("scope").hourlyRate == 40)
        #expect(try secondClients.earnings.load("scope").hourlyRate == 25)
        try firstClients.credentials.delete(first.connection.instance)
        #expect(try firstClients.credentials.read(first.connection.instance) == nil)
        #expect(try secondClients.credentials.read(second.connection.instance) == AlphaSampleData.token)
        try firstClients.loginItem.setEnabled(true)
        #expect(firstClients.loginItem.status() == .enabled)
        #expect(secondClients.loginItem.status() == .disabled)
        #expect(try await firstClients.biometrics.authenticate())
    }

    @Test func `demo refuses other server addresses and duplicate running timers`() async throws {
        let alpha = try AlphaEnvironment()
        let remote = try Connection(instance: "https://other.example.invalid", token: "fictional")
        await #expect(throws: AppError.self) { try await alpha.session.user(remote) }
        await #expect(throws: AppError.self) {
            try await alpha.session.create(
                alpha.connection, membership: AlphaSampleData.memberships[0],
                description: "Duplicate", project: nil, at: .now
            )
        }
    }

    private func clients(_ alpha: AlphaEnvironment) -> DependencyValues {
        withDependencies { alpha.configure(&$0) } operation: {
            @Dependency(\.self) var dependencies
            return dependencies
        }
    }
}
