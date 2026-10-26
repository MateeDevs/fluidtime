import Foundation

struct Failure: LocalizedError, Equatable, Sendable {
    var message: String

    var errorDescription: String? {
        message
    }

    init(_ error: any Error) {
        message = error.localizedDescription
    }
}
