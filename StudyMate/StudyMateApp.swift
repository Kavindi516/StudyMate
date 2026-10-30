import SwiftUI
import FirebaseCore
import CoreData

@main
struct StudyMateApp: App {
    @StateObject private var auth = AuthService()
    let persistence = PersistenceController.shared

    init() {
        AppEnvironment.prepareForUITesting()
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(auth)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
