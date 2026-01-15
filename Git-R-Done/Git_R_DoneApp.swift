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
    @Environment(\.openWindow) private var openWindow
    @State private var showOnboarding = !SettingsStore.shared.settings.hasCompletedOnboarding

    var body: some Scene {
        MenuBarExtra("Git-R-Done", systemImage: "checkmark.circle.fill") {
            Button("Settings...") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("About Git-R-Done") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }

            Button("Quit Git-R-Done") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)

        Window("Git-R-Done Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Welcome to Git-R-Done", id: "onboarding") {
            OnboardingView(isPresented: $showOnboarding)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
