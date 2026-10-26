import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var service = GroupService()
    @State private var showingCreate = false
    @State private var showingJoin = false

    var body: some View {
        NavigationStack {
            List {
                if service.groups.isEmpty {
                    ContentUnavailableView("No groups yet", systemImage: "person.2",
                        description: Text("Create or join a study group."))
                } else {
                    ForEach(service.groups) { group in
                        NavigationLink {
                            GroupDetailView(group: group)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(group.name).font(.headline)
                                Text("\(group.memberIds.count) members · \(group.module)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Create group") { showingCreate = true }
                        Button("Join with code") { showingJoin = true }
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New group")
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateGroupView(service: service).environmentObject(auth)
            }
            .sheet(isPresented: $showingJoin) {
                JoinGroupView(service: service).environmentObject(auth)
            }
            .task { if let uid = auth.uid { service.listenGroups(uid: uid) } }
        }
    }
}
