import Foundation

struct Connection: Equatable, Sendable {
    let instance: URL
    let token: String

    init(instance: String, token: String) throws {
        guard var components = URLComponents(string: instance.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = components.scheme?.lowercased(),
              ["https", "http"].contains(scheme), let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil
        else {
            throw AppError.message(String(localized: .enterAValidInstanceAddressSuchAsHttpsAppSolidtimeIo))
        }
        if scheme == "http" && !["localhost", "127.0.0.1", "::1"].contains(host) {
            throw AppError.message(String(localized: .useAnHttpsAddressToKeepYourApiKeySecure))
        }
        var path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path.hasSuffix("/api") {
            path = String(path.dropLast(4))
        }
        if path == "api" {
            path = ""
        }
        components.path = path.isEmpty ? "" : "/" + path
        guard let url = components.url else { throw AppError.message(String(localized: .enterAValidInstanceAddress)) }
        let token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { throw AppError.message(String(localized: .enterYourApiKey)) }
        self.instance = url
        self.token = token
    }
}
