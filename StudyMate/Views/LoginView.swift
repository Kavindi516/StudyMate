import SwiftUI

struct LoginView: View {
    @StateObject private var vm: AuthViewModel
    init(auth: AuthService) { _vm = StateObject(wrappedValue: AuthViewModel(auth: auth)) }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "book.closed.fill").font(.system(size: 60)).foregroundStyle(.tint)
            Text("StudyMate").font(.largeTitle).bold()
            Text("Plan. Attend. Study together.").foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Email", text: $vm.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $vm.password)
                    .textFieldStyle(.roundedBorder)
            }.padding(.horizontal)

            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote).padding(.horizontal)
            }

            Button { Task { await vm.login() } } label: {
                Text("Log In").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).padding(.horizontal).disabled(vm.isLoading)

            Button("Create an account") { Task { await vm.signUp() } }
                .disabled(vm.isLoading)
            Spacer()
        }
        .padding()
    }
}
