import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @State private var isUnlocked = false

    var body: some View {
        Group {
            if auth.isSignedIn {
                if isUnlocked {
                    MainTabView()          // ← your Phase 1 tab bar (see note)
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
