import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var service: GroupService
    @State private var name = ""
    @State private var module = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Group name", text: $name)
                TextField("Module", text: $module)
            }
            .navigationTitle("New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            if let uid = auth.uid {
                                try? await service.createGroup(name: name, module: module, ownerId: uid)
                            }
                            dismiss()
                        }
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
