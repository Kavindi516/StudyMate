
import SwiftUI
import FirebaseCore

@main
struct StudyMateApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
