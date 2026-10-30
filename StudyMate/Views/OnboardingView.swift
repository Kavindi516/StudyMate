import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "brain.head.profile", tint: .indigo,
                    title: "Smart Study Planner",
                    subtitle: "Plan sessions and let StudyMate suggest what to study next based on your deadlines."),
        OnboardPage(icon: "location.fill.viewfinder", tint: .green,
                    title: "Location Attendance",
                    subtitle: "Check in automatically when you arrive at class, with QR and NFC backup."),
        OnboardPage(icon: "person.3.fill", tint: .orange,
                    title: "Study Groups",
                    subtitle: "Create or join groups, share sessions, and stay in sync with your classmates."),
        OnboardPage(icon: "chart.bar.fill", tint: .pink,
                    title: "Track Your Progress",
                    subtitle: "See your study hours, attendance, and deadlines all in one place.")
    ]

    private var tint: Color { pages[page].tint }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    hasOnboarded = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [tint, tint.opacity(0.75)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                    .shadow(color: tint.opacity(0.35), radius: 10, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .accessibilityIdentifier("onboarding.next")

            Button("Skip") { hasOnboarded = true }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
                .opacity(page < pages.count - 1 ? 1 : 0)
                .disabled(page == pages.count - 1)
                .accessibilityIdentifier("onboarding.skip")
        }
        .background(
            LinearGradient(colors: [tint.opacity(0.16), Color(.systemGroupedBackground)],
                           startPoint: .top, endPoint: .center)
                .background(Color(.systemGroupedBackground))
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: page)
        )
    }

    private func pageView(_ p: OnboardPage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(p.tint.opacity(0.08)).frame(width: 220, height: 220)
                Circle().fill(p.tint.opacity(0.14)).frame(width: 170, height: 170)
                Image(systemName: p.icon)
                    .font(.system(size: 70, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [p.tint, p.tint.opacity(0.7)],
                                                    startPoint: .top, endPoint: .bottom))
            }
            VStack(spacing: 12) {
                Text(p.title).font(.title.bold()).multilineTextAlignment(.center)
                Text(p.subtitle)
                    .font(.body).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer(); Spacer()
        }
    }
}

private struct OnboardPage {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
}
