import Foundation

struct Membership: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let organization: Organization

    struct Organization: Decodable, Equatable, Sendable {
        let id: String
        let name: String
    }
}
