//
//  MainTabView.swift
//  StudyMate
//
//  Created by Student2 on 2026-10-21.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            ScheduleView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
            AttendanceView()
                .tabItem { Label("Attend", systemImage: "mappin.and.ellipse") }
            GroupsView()
                .tabItem { Label("Groups", systemImage: "person.2.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

// Placeholder screens — we fill these in later phases
struct SettingsView: View {
    var body: some View { NavigationStack { Text("Settings").navigationTitle("Settings") } }
}
