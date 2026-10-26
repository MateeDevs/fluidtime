@testable import FluidtimeCore
import Foundation
import Testing

@Suite(.serialized) struct APITests {
    private func api() throws -> SolidtimeAPI {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockProtocol.self]
        return try SolidtimeAPI(
            connection: Connection(instance: "https://example.invalid", token: "test-key"),
            session: URLSession(configuration: config)
        )
    }

    private func membership() throws -> Membership {
        try SolidtimeAPI.decoder().decode(
            Membership.self, from: Data(#"{"id":"member-id","organization":{"id":"org-id","name":"Test"}}"#.utf8)
        )
    }

    private var entryJSON: String {
        #"""
        {"id":"entry","start":"2026-10-21T10:00:00Z","end":null,"description":"Work",
            "project_id":"project","task_id":null,
        "organization_id":"org-id","user_id":"me","billable":true,"tags":[],"type":"work"}
        """#
    }

    @Test func `paginates and scopes every page to member`() async throws {
        let entryJSON = entryJSON
        MockProtocol.handler = { request in
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            #expect(items.contains(URLQueryItem(name: "member_id", value: "member-id")))
            #expect(items.contains(URLQueryItem(name: "limit", value: "500")))
            let offset = items.first { $0.name == "offset" }!.value!
            let entry = offset == "0" ? entryJSON : entryJSON.replacingOccurrences(of: "\"entry\"", with: "\"entry-2\"")
            return (200, Data("{\"data\":[\(entry)],\"meta\":{\"total\":2}}".utf8))
        }
        let entries = try await api().entries(membership: membership())
        #expect(entries.map(\.id) == ["entry", "entry-2"])
    }

    @Test func `creates with member billable and explicit nulls`() async throws {
        let entryJSON = entryJSON
        MockProtocol.handler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url!.path == "/api/v1/organizations/org-id/time-entries")
            // URLSession may provide the body as an input stream to URLProtocol.
            let body = try Self.body(request)
            #expect(body["member_id"] as? String == "member-id")
            #expect(body["billable"] as? Bool == true)
            #expect(body["project_id"] as? String == "project")
            #expect(body["end"] is NSNull)
            #expect(body["task_id"] is NSNull)
            #expect(body["type"] as? String == "work")
            return (200, Data("{\"data\":\(entryJSON)}".utf8))
        }
        let project = try SolidtimeAPI.decoder().decode(
            Project.self,
            from: Data(
                ##"{"id":"project","name":"Project","color":"#ffffff","is_archived":false,"is_billable":true}"##.utf8
            )
        )
        _ = try await api().create(membership: membership(), description: "Work", project: project)
    }

    @Test func `stops without overwriting other fields`() async throws {
        let entryJSON = entryJSON
        MockProtocol.handler = { request in
            #expect(request.httpMethod == "PUT")
            let body = try Self.body(request)
            #expect(body.count == 2)
            #expect(body["member_id"] as? String == "member-id")
            #expect(body["end"] as? String == "2026-10-21T11:00:00Z")
            return (200, Data("{\"data\":\(entryJSON)}".utf8))
        }
        let entry = try SolidtimeAPI.decoder().decode(TimeEntry.self, from: Data(entryJSON.utf8))
        _ = try await api().update(entry, memberId: "member-id", changes: ["end": "2026-10-21T11:00:00Z"])
    }

    @Test func `handles absent active timer and authentication error`() async throws {
        MockProtocol.handler = { _ in (404, Data()) }
        #expect(try await api().activeEntry() == nil)
        MockProtocol.handler = { _ in (401, Data()) }
        do {
            _ = try await api().user()
            Issue.record("Expected an authentication error")
        } catch let AppError.http(status) { #expect(status == 401) }
    }

    @Test func `deletes an entry using its organization and accepts an empty 204 response`() async throws {
        let entry = try SolidtimeAPI.decoder().decode(TimeEntry.self, from: Data(entryJSON.utf8))
        MockProtocol.handler = { request in
            #expect(request.httpMethod == "DELETE")
            #expect(request.url?.path == "/api/v1/organizations/org-id/time-entries/entry")
            #expect(request.url?.query == nil)
            #expect(request.httpBody == nil)
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
            return (204, Data())
        }
        try await api().delete(entry)
        MockProtocol.handler = { _ in (403, Data()) }
        do {
            try await api().delete(entry)
            Issue.record("Expected deletion authorization failure")
        } catch let AppError.http(status) { #expect(status == 403) }
    }

    private static func body(_ request: URLRequest) throws -> [String: Any] {
        var data = request.httpBody ?? Data()
        if data.isEmpty, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var bytes = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let count = stream.read(&bytes, maxLength: bytes.count)
                if count <= 0 {
                    break
                }
                data.append(contentsOf: bytes.prefix(count))
            }
        }
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
