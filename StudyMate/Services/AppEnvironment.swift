import Foundation

/// Launch-argument switches used only by the UI test target.
/// Without `-UITesting` the app behaves exactly as it does for users.
enum AppEnvironment {
    private static let arguments = ProcessInfo.processInfo.arguments

    /// Use an in-memory store, skip system permission prompts and ignore Firebase auth state.
    static let isUITesting = arguments.contains("-UITesting")
    /// With `-UITesting`: behave as if a user is signed in.
    static let uiTestSignedIn = arguments.contains("-UITestingSignedIn")
    /// With `-UITesting`: start on the onboarding flow instead of skipping it.
    static let uiTestShowOnboarding = arguments.contains("-UITestingShowOnboarding")

    /// Puts persisted preferences into a known state so every UI test starts clean.
    static func prepareForUITesting() {
        guard isUITesting else { return }
        let defaults = UserDefaults.standard
        defaults.set(!uiTestShowOnboarding, forKey: "hasOnboarded")
        defaults.set(false, forKey: "biometricLock")
        defaults.set("light", forKey: "appTheme")
        defaults.set(true, forKey: "notificationsEnabled")
    }
}
