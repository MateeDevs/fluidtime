import Foundation

struct SolidtimeUser: Decodable, Equatable, Sendable {
    let id: String
    let name: String
    let timezone: String
    let weekStart: String

    var localizedWeekStart: String {
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let index = weekdays.firstIndex(of: weekStart.lowercased()) ?? 1
        return calendar.weekdaySymbols[index]
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        calendar.firstWeekday = (weekdays.firstIndex(of: weekStart.lowercased()) ?? 1) + 1
        calendar.minimumDaysInFirstWeek = 1
        return calendar
    }
}
