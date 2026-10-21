import SwiftUI
import FirebaseCore

@main
struct StudyMateApp: App {
    @StateObject private var auth = AuthService()

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(auth)
        }
    }
}
