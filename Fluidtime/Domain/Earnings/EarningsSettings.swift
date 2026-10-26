import Foundation

struct EarningsSettings: Codable, Equatable, Sendable {
    var currency = Locale.current.currency?.identifier ?? "USD"
    var hourlyRate = Decimal.zero
}

extension EarningsSettings {
    private enum CodingKeys: String, CodingKey { case currency, hourlyRate }

    init(from decoder: any Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        currency = try values.decodeIfPresent(String.self, forKey: .currency) ?? currency
        hourlyRate = try values.decodeIfPresent(Decimal.self, forKey: .hourlyRate) ?? hourlyRate
    }
}

enum EarningsCalculator {
    static func estimate(_ analysis: TimeAnalysis, settings: EarningsSettings, billableOnly: Bool) -> Decimal {
        guard !settings.hourlyRate.isNaN, settings.hourlyRate >= 0 else { return 0 }
        let seconds = analysis.days.reduce(0) { $0 + (billableOnly ? $1.billable : $1.work) }
        return Decimal(seconds) / 3600 * settings.hourlyRate
    }
}
