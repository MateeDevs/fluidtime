import Foundation

enum AppError: LocalizedError, Equatable {
    case message(String)
    case http(Int)

    var errorDescription: String? {
        switch self {
        case let .message(text): text
        case .http(401): String(localized: .yourApiKeyWasntAcceptedCheckItInSettings)
        case .http(403): String(localized: .yourApiKeyDoesntHavePermissionForThisAction)
        case .http(404): String(localized: .thisItemCouldntBeFoundRefreshAndTryAgain)
        case .http(409), .http(422):
            String(localized: .solidtimeCouldntSaveThisEntryRefreshAndCheckYourTimerAndProject)
        case .http(429): String(localized: .tooManyRequestsWaitAMomentThenTryAgain)
        case .http: String(localized: .solidtimeCouldntCompleteTheRequestTryAgainInAMoment)
        }
    }
}
