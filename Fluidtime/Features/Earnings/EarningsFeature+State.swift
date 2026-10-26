import ComposableArchitecture
import Foundation

extension EarningsFeature {
    @ObservableState
    struct State: Equatable {
        var accountScope = ""
        var surface: Surface?
        var pendingSurface: Surface?
        var settings: EarningsSettings?
        var savedSettings: EarningsSettings?
        var operation: UUID?
        var showsProgress = false
        var error: String?

        var hasChanges: Bool {
            settings != savedSettings
        }
    }

    enum Surface: Equatable, Sendable { case settings, preview }

    @CasePathable
    enum Action: ViewAction, Equatable {
        case view(View)
        case interface(Interface)
        case unlockResponse(UUID, Result<EarningsSettings?, Failure>)
        case saveResponse(UUID, Failure?)
        case showProgress(UUID)
    }

    enum View: Equatable {
        case reveal(Surface)
        case conceal(Surface)
        case rateChanged(Decimal)
        case currencyChanged(String)
        case save
    }

    enum Interface: Equatable {
        case contextChanged(String)
        case conceal(Surface)
        case lock
    }
}
