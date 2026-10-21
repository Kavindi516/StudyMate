import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let auth: AuthService
    init(auth: AuthService) { self.auth = auth }

    func login() async {
        isLoading = true; errorMessage = nil
        do { try await auth.signIn(email: email, password: password) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func signUp() async {
        isLoading = true; errorMessage = nil
        do { try await auth.signUp(email: email, password: password) }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
