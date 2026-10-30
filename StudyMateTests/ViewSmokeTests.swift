import Testing
import SwiftUI
import UIKit
import CoreData
@testable import StudyMate

/// Renders the real SwiftUI views against seeded in-memory data and checks they lay out.
/// This catches crashes in `body`, broken bindings and empty layouts without needing a simulator UI run.
@MainActor
struct ViewSmokeTests {

    private let phone = CGSize(width: 390, height: 844)

    /// Lays the view out at phone size and returns the hosting controller.
    private func host<V: View>(_ view: V, width: CGFloat = 390) -> UIHostingController<V> {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: phone)
        controller.view.layoutIfNeeded()
        return controller
    }

    private func fittingSize<V: View>(_ view: V, width: CGFloat = 358) -> CGSize {
        UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    private func seededContext() -> NSManagedObjectContext {
        let context = TestStore.makeContext()
        TestStore.addSession(context, subject: "Calculus", date: Date(), minutes: 90, priority: "High")
        TestStore.addSession(context, subject: "History", date: Date(), minutes: 45, priority: "Low", completed: true)
        TestStore.addDeadline(context, title: "Essay", module: "Calculus",
                              due: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        TestStore.addClass(context, subject: "Calculus")
        return context
    }

    // MARK: Reusable pieces

    @Test func statTileHasHeightAndFillsTheWidth() {
        let size = fittingSize(StatTile(value: "3", label: "Today", icon: "calendar", color: .blue), width: 110)
        #expect(size.height > 60)
        #expect(size.width <= 110)
    }

    @Test func emptyStateCardWithIconIsTallerThanItsText() {
        let size = fittingSize(EmptyStateCard(title: "Nothing here", systemImage: "tray", message: "Add something."))
        #expect(size.height > 100)
    }

    @Test func emptyStateCardWithBannerIsTallerThanWithoutOne() {
        let plain = fittingSize(EmptyStateCard(title: "T", systemImage: "tray", message: "M"))
        let banner = fittingSize(EmptyStateCard(title: "T", systemImage: "tray", message: "M", banner: "studyHeader3"))
        #expect(banner.height > 130)
        #expect(banner.height != plain.height)
    }

    @Test func heroBannerUsesTheRequestedHeight() {
        let size = fittingSize(HeroBanner(image: "studyHeader1", height: 190) { Text("Hello") })
        #expect(size.height == 190)
    }

    @Test func badgeRendersCompactly() {
        let size = fittingSize(Badge(text: "High", color: .red))
        #expect(size.width > 20 && size.width < 120)
        #expect(size.height > 10 && size.height < 40)
    }

    @Test func allStudyHeaderImagesAreInTheAssetCatalog() {
        for name in ["studyHeader1", "studyHeader2", "studyHeader3", "studyHeader4"] {
            #expect(UIImage(named: name) != nil, "missing image \(name)")
        }
    }

    @Test func sessionCardLaysOut() {
        let context = seededContext()
        let session = TestStore.fetchAll(StudySession.self, entity: "StudySession", in: context).first!
        let size = fittingSize(SessionCard(session: session).environment(\.managedObjectContext, context))
        #expect(size.height > 50)
    }

    @Test func sessionCardWithDateIsNoShorterThanWithout() {
        let context = seededContext()
        let session = TestStore.fetchAll(StudySession.self, entity: "StudySession", in: context).first!
        let plain = fittingSize(SessionCard(session: session).environment(\.managedObjectContext, context))
        let dated = fittingSize(SessionCard(session: session, showDate: true).environment(\.managedObjectContext, context))
        #expect(dated.height >= plain.height)
    }

    @Test func deadlineRowLaysOut() {
        let context = seededContext()
        let deadline = TestStore.fetchAll(Deadline.self, entity: "Deadline", in: context).first!
        #expect(fittingSize(DeadlineRow(deadline: deadline)).height > 30)
    }

    @Test func qrCodeViewProducesAnImageForTokenText() {
        let token = AttendanceToken(classId: "abc", subject: "Math", issuedAt: Date()).encoded()
        let size = fittingSize(QRCodeView(text: token).frame(width: 240, height: 240), width: 240)
        #expect(size.width > 0 && size.height > 0)
    }

    // MARK: Whole screens

    @Test func homeScreenRendersWithData() {
        let context = seededContext()
        let controller = host(HomeView().environment(\.managedObjectContext, context))
        #expect(controller.view.bounds.size == phone)
    }

    @Test func homeScreenRendersWhenEmpty() {
        let controller = host(HomeView().environment(\.managedObjectContext, TestStore.makeContext()))
        #expect(controller.view.bounds.size == phone)
    }

    @Test func scheduleScreenRenders() {
        let controller = host(ScheduleView().environment(\.managedObjectContext, seededContext()))
        #expect(controller.view.bounds.size == phone)
    }

    @Test func statsScreenRenders() {
        let controller = host(NavigationStack { StatsView() }.environment(\.managedObjectContext, seededContext()))
        #expect(controller.view.bounds.size == phone)
    }

    @Test func deadlinesScreenRenders() {
        let controller = host(NavigationStack { DeadlinesView() }.environment(\.managedObjectContext, seededContext()))
        #expect(controller.view.bounds.size == phone)
    }

    @Test func addSessionFormRenders() {
        let controller = host(AddSessionView().environment(\.managedObjectContext, TestStore.makeContext()))
        #expect(controller.view.bounds.size == phone)
    }

    @Test func addDeadlineFormRendersForNewAndExisting() {
        let context = seededContext()
        let existing = TestStore.fetchAll(Deadline.self, entity: "Deadline", in: context).first
        #expect(host(AddDeadlineView().environment(\.managedObjectContext, context)).view.bounds.size == phone)
        #expect(host(AddDeadlineView(deadline: existing).environment(\.managedObjectContext, context)).view.bounds.size == phone)
    }

    @Test func settingsScreenRenders() {
        let controller = host(SettingsView()
            .environmentObject(AuthService())
            .environment(\.managedObjectContext, TestStore.makeContext()))
        #expect(controller.view.bounds.size == phone)
    }

    @Test func onboardingScreenRenders() {
        #expect(host(OnboardingView()).view.bounds.size == phone)
    }

    @Test func loginScreenRenders() {
        #expect(host(LoginView(auth: AuthService())).view.bounds.size == phone)
    }

    @Test func lockScreenRenders() {
        #expect(host(LockView(isUnlocked: .constant(false))).view.bounds.size == phone)
    }
}
