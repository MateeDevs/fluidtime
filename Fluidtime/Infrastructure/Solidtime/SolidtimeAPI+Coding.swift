import Foundation

extension SolidtimeAPI {
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: text) {
                return date
            }
            formatter.formatOptions.insert(.withFractionalSeconds)
            guard let date = formatter.date(from: text) else {
                throw try DecodingError.dataCorruptedError(
                    in: decoder.singleValueContainer(), debugDescription: "Invalid timestamp"
                )
            }
            return date
        }
        return decoder
    }

    static func timestamp(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
