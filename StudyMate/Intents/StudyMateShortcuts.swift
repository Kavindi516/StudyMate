import AppIntents

struct StudyMateShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddStudySessionIntent(),
            phrases: [
                "Add a study session in \(.applicationName)",
                "Create a study session in \(.applicationName)"
            ],
            shortTitle: "Add Study Session",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: NextSessionIntent(),
            phrases: [
                "What's my next session in \(.applicationName)",
                "What's my next class in \(.applicationName)"
            ],
            shortTitle: "Next Session",
            systemImageName: "calendar"
        )
    }
}
