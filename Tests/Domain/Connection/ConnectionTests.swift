@testable import FluidtimeCore
import Foundation
import Testing

struct ConnectionTests {
    @Test func `normalizes instance and rejects unsafe addresses`() throws {
        #expect(
            try Connection(instance: " https://example.com/solidtime/api/ ", token: " key ").instance.absoluteString
                == "https://example.com/solidtime"
        )
        #expect(try Connection(instance: "https://example.com/api", token: "key").token == "key")
        #expect(throws: AppError.self) { try Connection(instance: "http://example.com", token: "key") }
        #expect(throws: AppError.self) { try Connection(instance: "https://user:secret@example.com", token: "key") }
        #expect(throws: AppError.self) { try Connection(instance: "https://example.com?token=value", token: "key") }
        #expect(throws: AppError.self) { try Connection(instance: "https://example.com", token: " ") }
    }
}
