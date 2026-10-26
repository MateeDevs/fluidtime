import Foundation

struct SolidtimeAPI: Sendable {
    let connection: Connection
    private let session: URLSession

    init(connection: Connection, session: URLSession) {
        self.connection = connection
        self.session = session
    }

    func request<Value: Decodable>(
        _ path: String, query: [URLQueryItem] = [],
        method: String = "GET", body: [String: Any]? = nil
    ) async throws -> Value {
        let data = try await responseData(path, query: query, method: method, body: body)
        do { return try Self.decoder().decode(Value.self, from: data) } catch {
            throw AppError.message(
                String(localized: .thisInstanceReturnedAnUnexpectedResponseCheckThatItSupportsTheSolidtimeApi)
            )
        }
    }

    func requestWithoutResponse(_ path: String, method: String) async throws {
        _ = try await responseData(path, method: method)
    }

    private func responseData(
        _ path: String, query: [URLQueryItem] = [], method: String, body: [String: Any]? = nil
    ) async throws -> Data {
        let base = connection.instance.appendingPathComponent("api").appendingPathComponent("v1")
        var components = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("Bearer \(connection.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw AppError.message(String(localized: .couldntReadTheResponseFromSolidtime))
        }
        guard (200 ..< 300).contains(response.statusCode) else { throw AppError.http(response.statusCode) }
        return data
    }
}
