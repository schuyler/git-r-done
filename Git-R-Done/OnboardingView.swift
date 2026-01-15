//
//  OnboardingView.swift
//  Git-R-Done
//
//  Created by Schuyler Erle on 1/14/26.
//

import SwiftUI
import GitRDoneShared

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.accentColor)

            Text("Welcome to Git-R-Done")
                .font(.title)
                .fontWeight(.bold)

            Text("Git integration for Finder")
                .font(.headline)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                StepView(
                    number: 1,
                    title: "Enable the Finder Extension",
                    description: "Open System Settings and enable Git-R-Done in Privacy & Security > Extensions > Finder.",
                    isActive: currentStep == 0
                )

                Button("Open System Settings") {
                    openFinderExtensionSettings()
                    currentStep = 1
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentStep != 0)

                StepView(
                    number: 2,
                    title: "Add Your First Repository",
                    description: "Click the Git-R-Done icon in your menu bar and add a Git repository to start tracking.",
                    isActive: currentStep == 1
                )
            }
            .padding()

            Spacer()

            HStack {
                Button("Don't Show Again") {
                    completeOnboarding()
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Get Started") {
                    completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 450, height: 400)
    }

    private func openFinderExtensionSettings() {
        // Open System Settings to Extensions > Finder
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?Extensions") {
            NSWorkspace.shared.open(url)
        }
    }

    private func completeOnboarding() {
        var settings = SettingsStore.shared.settings
        settings.hasCompletedOnboarding = true
        SettingsStore.shared.update(settings)
        isPresented = false

        // Close the onboarding window
        NSApplication.shared.windows.first { $0.identifier?.rawValue == "onboarding" }?.close()
    }
}

struct StepView: View {
    let number: Int
    let title: String
    let description: String
    let isActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isActive ? .primary : .secondary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
