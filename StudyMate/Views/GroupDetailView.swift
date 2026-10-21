import SwiftUI

struct GroupDetailView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var vm: GroupDetailViewModel
    @State private var showingAdd = false

    init(group: StudyGroup) { _vm = StateObject(wrappedValue: GroupDetailViewModel(group: group)) }

    var body: some View {
        List {
            Section("Group code (share to invite)") {
                if let id = vm.group.id {
                    Text(id).font(.footnote).textSelection(.enabled)
                }
            }
            Section("Shared sessions") {
                if vm.sessions.isEmpty {
                    Text("No sessions yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(vm.sessions) { s in
                        VStack(alignment: .leading) {
                            Text(s.title)
                            Text("\(s.date, style: .date) · \(s.date, style: .time)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Members") { Text("\(vm.group.memberIds.count) members") }
        }
        .navigationTitle(vm.group.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddGroupSessionView(vm: vm).environmentObject(auth)
        }
        .task { vm.listen() }
    }
}
