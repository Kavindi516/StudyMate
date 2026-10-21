import SwiftUI

struct JoinGroupView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var service: GroupService
    @State private var code = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group code", text: $code)
                        .textInputAutocapitalization(.never)
                } footer: {
                    Text("Paste the group code shared by the group owner.")
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Join Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Join") {
                        Task {
                            do {
                                if let uid = auth.uid {
                                    try await service.joinGroup(
                                        code: code.trimmingCharacters(in: .whitespaces), uid: uid)
                                }
                                dismiss()
                            } catch { self.error = "Couldn't join. Check the code." }
                        }
                    }.disabled(code.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
