import Foundation
import LocalAuthentication

final class BiometricService {
    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        // .deviceOwnerAuthentication = Face ID / Touch ID with passcode fallback
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return true // no biometrics set up — don't lock the user out (e.g. simulator)
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock StudyMate to protect your academic data."
            )
        } catch { return false }
    }
}
