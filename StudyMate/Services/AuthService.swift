import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthService: ObservableObject {
    @Published var user: User?
    var uid: String? { user?.uid }
    private var handle: AuthStateDidChangeListenerHandle?

    // Called AFTER FirebaseApp.configure() has run (from RootView.task)
    func start() {
        guard handle == nil else { return }
        user = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    var isSignedIn: Bool { user != nil }

    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
