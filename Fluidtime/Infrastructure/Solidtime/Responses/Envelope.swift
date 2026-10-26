import Foundation

struct Envelope<Value: Decodable>: Decodable {
    let data: Value
}
