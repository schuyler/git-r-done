//
//  Git_R_DoneApp.swift
//  Git-R-Done
//
//  Created by Schuyler Erle on 1/14/26.
//

import SwiftUI
import GitRDoneShared

@main
struct Git_R_DoneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showOnboarding = !SettingsStore.shared.settings.hasCompletedOnboarding

    var body: some Scene {
        MenuBarExtra("Git-R-Done", systemImage: "checkmark.circle.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Window("Welcome to Git-R-Done", id: "onboarding") {
            OnboardingView(isPresented: $showOnboarding)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
