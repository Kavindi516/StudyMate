import SwiftUI
import CoreData

struct RootView: View {
    @AppStorage("biometricLock") private var biometricLock = true
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject var auth: AuthService
    @State private var isUnlocked = false

    var body: some View {
        Group {
            if !hasOnboarded {
                OnboardingView()
            } else if isSignedIn {
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
            WidgetUpdater.refresh(context: PersistenceController.shared.container.viewContext)
            if !AppEnvironment.isUITesting {
                NotificationService.shared.requestAuthorization()
            }
        }
        .preferredColorScheme(scheme)
    }

    private var isSignedIn: Bool {
        AppEnvironment.isUITesting ? AppEnvironment.uiTestSignedIn : auth.isSignedIn
    }

    private var scheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
}
