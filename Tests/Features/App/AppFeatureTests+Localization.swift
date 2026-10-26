import ComposableArchitecture
@testable import FluidtimeCore
import Foundation
import Testing

extension AppFeatureTests {
    @Test func `localized interpolations preserve user text`() {
        #expect(String(localized: .durationUnavailable) == "—")
        let name = "Alex %@"
        #expect(String(localized: .connectedAs(name)) == "Connected as Alex %@")
        #expect(String(localized: .elapsedTime("1:02:03")) == "Elapsed time 1:02:03")
        #expect(user.localizedWeekStart == user.calendar.weekdaySymbols[1])
    }
}
