import Foundation

struct Project: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let color: String
    let isArchived: Bool
    let isBillable: Bool
}
