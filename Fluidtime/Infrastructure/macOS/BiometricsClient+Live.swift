import ComposableArchitecture
import Foundation
import LocalAuthentication

extension BiometricsClient: DependencyKey {
    static let liveValue = Self(authenticate: { try await TouchIDSession().authenticate() })
}

@MainActor
private final class TouchIDSession {
    private let context = LAContext()

    func authenticate() async throws -> Bool {
        context.localizedCancelTitle = String(localized: .cancel)
        context.localizedFallbackTitle = ""
        context.touchIDAuthenticationAllowableReuseDuration = 0
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error),
              context.biometryType == .touchID
        else {
            if (error as? LAError)?.code == .biometryLockout {
                throw AppError.message(String(localized: .earningsTouchIdLocked))
            }
            throw AppError.message(String(localized: .earningsTouchIdUnavailable))
        }
        let result = try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: String(localized: .earningsTouchIdReason)
                ) { success, error in
                    if success {
                        continuation.resume(returning: true)
                        return
                    }
                    let code = (error as? LAError)?.code
                    let cancelled = code == .userCancel || code == .systemCancel || code == .appCancel
                    if cancelled {
                        continuation.resume(returning: false)
                    } else if code == .biometryLockout {
                        continuation.resume(throwing: AppError.message(String(localized: .earningsTouchIdLocked)))
                    } else {
                        continuation.resume(throwing: AppError.message(String(localized: .earningsTouchIdFailed)))
                    }
                }
            }
        } onCancel: {
            Task { @MainActor [self] in context.invalidate() }
        }
        context.invalidate()
        return result
    }
}
