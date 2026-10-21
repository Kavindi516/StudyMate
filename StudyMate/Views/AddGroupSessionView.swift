import SwiftUI

struct AddGroupSessionView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: GroupDetailViewModel
    @State private var title = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                DatePicker("Date & time", selection: $date)
            }
            .navigationTitle("Shared Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let uid = auth.uid {
                            try? vm.addSession(title: title, date: date, createdBy: uid)
                        }
                        dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
