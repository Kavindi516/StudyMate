import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var service = GroupService()
    @State private var showingCreate = false
    @State private var showingJoin = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if service.groups.isEmpty {
                        emptyCard
                    } else {
                        ForEach(service.groups) { group in
                            NavigationLink { GroupDetailView(group: group) } label: { groupCard(group) }
                                .buttonStyle(.plain)
                        }
                    }
                    Spacer(minLength: 10)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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
            .sheet(isPresented: $showingCreate) { CreateGroupView(service: service).environmentObject(auth) }
            .sheet(isPresented: $showingJoin) { JoinGroupView(service: service).environmentObject(auth) }
            .task { if let uid = auth.uid { service.listenGroups(uid: uid) } }
        }
    }

    private func groupCard(_ group: StudyGroup) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.3.fill")
                .font(.title3).foregroundStyle(.indigo)
                .frame(width: 44, height: 44)
                .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                Text(group.name).font(.body.weight(.semibold))
                Text("\(group.memberIds.count) members · \(group.module)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(14)
        .softCard()
    }

    private var emptyCard: some View {
        EmptyStateCard(title: "No groups yet", systemImage: "person.2",
                       message: "Create or join a study group.")
    }
}
