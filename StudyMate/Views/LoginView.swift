import SwiftUI

struct LoginView: View {
    @StateObject private var vm: AuthViewModel
    @State private var isSignUp = false
    init(auth: AuthService) { _vm = StateObject(wrappedValue: AuthViewModel(auth: auth)) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.indigo.opacity(0.18), Color(.systemBackground)],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.indigo, .blue],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 84, height: 84)
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 34)).foregroundStyle(.white)
                        }
                        Text("StudyMate").font(.largeTitle.bold())
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)

                    VStack(spacing: 16) {
                        Picker("", selection: $isSignUp) {
                            Text("Log In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("login.mode")
                        .onChange(of: isSignUp) { _, _ in vm.errorMessage = nil }

                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "envelope").foregroundStyle(.secondary).frame(width: 20)
                                TextField("Email", text: $vm.email)
                                    .textInputAutocapitalization(.never).keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("login.email")
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                            HStack {
                                Image(systemName: "lock").foregroundStyle(.secondary).frame(width: 20)
                                SecureField("Password", text: $vm.password)
                                    .accessibilityIdentifier("login.password")
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        }

                        if let error = vm.errorMessage {
                            Text(error).foregroundStyle(.red).font(.footnote)
                        }

                        Button {
                            Task { isSignUp ? await vm.signUp() : await vm.login() }
                        } label: {
                            if vm.isLoading {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Text(isSignUp ? "Create Account" : "Log In")
                                    .bold().frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(vm.isLoading || vm.email.isEmpty || vm.password.isEmpty)
                        .accessibilityIdentifier("login.submit")
                    }
                    .padding()
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
