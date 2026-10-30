import Testing
import Foundation
import FirebaseFirestore
@testable import StudyMate

@MainActor
struct ViewModelAndModelTests {

    // MARK: AuthViewModel / AuthService

    @Test func authServiceStartsSignedOut() {
        let auth = AuthService()
        #expect(auth.isSignedIn == false)
        #expect(auth.uid == nil)
    }

    @Test func loginFormStartsEmptyAndIdle() {
        let vm = AuthViewModel(auth: AuthService())
        #expect(vm.email.isEmpty)
        #expect(vm.password.isEmpty)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test(.timeLimit(.minutes(1)))
    func loginWithAnInvalidAccountShowsAnErrorAndStopsLoading() async {
        let vm = AuthViewModel(auth: AuthService())
        vm.email = "not-an-email"
        vm.password = "x"
        await vm.login()
        #expect(vm.errorMessage?.isEmpty == false)
        #expect(vm.isLoading == false)
    }

    @Test(.timeLimit(.minutes(1)))
    func signUpWithAnInvalidEmailShowsAnError() async {
        let vm = AuthViewModel(auth: AuthService())
        vm.email = "still-not-an-email"
        vm.password = "123"
        await vm.signUp()
        #expect(vm.errorMessage?.isEmpty == false)
        #expect(vm.isLoading == false)
    }

    // MARK: Firestore models

    @Test func studyGroupKeepsItsFields() {
        let created = Date()
        let group = StudyGroup(name: "Night Owls", module: "CS101", ownerId: "u1",
                               memberIds: ["u1", "u2"], createdAt: created)
        #expect(group.name == "Night Owls")
        #expect(group.module == "CS101")
        #expect(group.ownerId == "u1")
        #expect(group.memberIds == ["u1", "u2"])
        #expect(group.createdAt == created)
        #expect(group.id == nil) // assigned by Firestore
    }

    @Test func newGroupHasTheOwnerAsTheOnlyMember() {
        let group = StudyGroup(name: "G", module: "M", ownerId: "owner", memberIds: ["owner"], createdAt: Date())
        #expect(group.memberIds.count == 1)
        #expect(group.memberIds.contains(group.ownerId))
    }

    @Test func groupSessionKeepsItsFields() {
        let date = Date()
        let session = GroupSession(title: "Revision", date: date, createdBy: "u1")
        #expect(session.title == "Revision")
        #expect(session.date == date)
        #expect(session.createdBy == "u1")
    }

    @Test func studyGroupEncodesTheFieldsFirestoreStores() throws {
        let created = Date(timeIntervalSince1970: 1_800_000_000)
        let group = StudyGroup(name: "Night Owls", module: "CS101", ownerId: "u1",
                               memberIds: ["u1", "u2"], createdAt: created)
        let data = try Firestore.Encoder().encode(group)
        #expect(data["name"] as? String == "Night Owls")
        #expect(data["module"] as? String == "CS101")
        #expect(data["ownerId"] as? String == "u1")
        #expect(data["memberIds"] as? [String] == ["u1", "u2"])
        #expect((data["createdAt"] as? Timestamp)?.dateValue() == created)
        #expect(data["id"] == nil) // the document id lives in the path, not the body
    }

    @Test func groupSessionEncodesTheFieldsFirestoreStores() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let data = try Firestore.Encoder().encode(GroupSession(title: "Mock exam", date: date, createdBy: "u9"))
        #expect(data["title"] as? String == "Mock exam")
        #expect(data["createdBy"] as? String == "u9")
        #expect((data["date"] as? Timestamp)?.dateValue() == date)
        #expect(data["id"] == nil)
    }

    // MARK: Test-mode switches

    @Test func uiTestingSwitchesAreOffInNormalRuns() {
        // Guards against the test-only launch mode leaking into the real app.
        #expect(AppEnvironment.isUITesting == false)
        #expect(AppEnvironment.uiTestSignedIn == false)
        #expect(AppEnvironment.uiTestShowOnboarding == false)
    }

    @Test func preparingForUITestingIsANoOpOutsideUITests() {
        let key = "hasOnboarded"
        let before = UserDefaults.standard.object(forKey: key)
        AppEnvironment.prepareForUITesting()
        #expect(UserDefaults.standard.object(forKey: key) as? Bool == before as? Bool)
    }
}
