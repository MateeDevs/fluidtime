import Foundation

struct CollectionPage<Value: Decodable>: Decodable {
    let data: [Value]
    let meta: Metadata?

    struct Metadata: Decodable {
        let total: Int?
        let lastPage: Int?
    }
}
