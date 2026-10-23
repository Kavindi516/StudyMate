import SwiftUI

struct RootView: View {
    @AppStorage("biometricLock") private var biometricLock = true
    @EnvironmentObject var auth: AuthService
    @State private var isUnlocked = false

    var body: some View {
        Group {
            if auth.isSignedIn {
                if isUnlocked || !biometricLock {
                    MainTabView()
                } else {
                    LockView(isUnlocked: $isUnlocked)
                }
            } else {
                LoginView(auth: auth)
            }
        }
        .task {
            auth.start()
            NotificationService.shared.requestAuthorization()}
    }
}
