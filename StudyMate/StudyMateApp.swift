//
//  StudyMateApp.swift
//  StudyMate
//
//  Created by Student2 on 2026-10-05.
//

import SwiftUI
import FirebaseCore

@main
struct StudyMateApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
