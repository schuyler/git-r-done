//
//  Git_R_DoneApp.swift
//  Git-R-Done
//
//  Created by Schuyler Erle on 1/14/26.
//

import SwiftUI
import GitRDoneShared

// MARK: - Menu Bar View Model

@Observable
final class MenuBarViewModel {
    private let repoConfiguration: RepoConfiguring
    private let statusCache: StatusCaching
    private var observers: [Any] = []

    var summaries: [RepoStatusSummary] = []

    init(
        repoConfiguration: RepoConfiguring = RepoConfiguration.shared,
        statusCache: StatusCaching = SharedStatusCache.shared
    ) {
        self.repoConfiguration = repoConfiguration
        self.statusCache = statusCache
        loadSummaries()

        observers.append(
            NotificationCenter.default.addObserver(
                forName: .statusCacheDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.loadSummaries()
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(
                forName: .repositoriesDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.loadSummaries()
            }
        )
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func loadSummaries() {
        summaries = repoConfiguration.repositories.map { repo in
            if let cached = statusCache.summary(for: repo.path) {
                return cached
            }
            return RepoStatusSummary(path: repo.path, status: .pending)
        }
    }
}

// MARK: - App Entry Point

@main
struct Git_R_DoneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    @State private var showOnboarding = !SettingsStore.shared.settings.hasCompletedOnboarding
    @State private var menuViewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra("Git-R-Done", systemImage: "checkmark.circle.fill") {
            if menuViewModel.summaries.isEmpty {
                Text("No repositories")
                    .foregroundColor(.secondary)
                Text("Add one in Settings...")
                    .foregroundColor(.secondary)
            } else {
                ForEach(menuViewModel.summaries, id: \.path) { summary in
                    Button {
                        openInFinder(path: summary.path)
                    } label: {
                        HStack {
                            statusIcon(for: summary.status)
                            Text(summary.displayName)
                        }
                    }
                }
            }

            Divider()

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

    // MARK: - Helper Methods

    @ViewBuilder
    private func statusIcon(for priority: BadgePriority) -> some View {
        let (symbol, color): (String, Color) = switch priority {
        case .pending: ("ellipsis.circle", .gray)
        case .clean: ("checkmark.circle.fill", .green)
        case .ahead: ("arrow.up.circle.fill", .blue)
        case .untracked: ("questionmark.circle", .gray)
        case .staged: ("circle.fill", .yellow)
        case .modified: ("circle.fill", .orange)
        case .conflict: ("exclamationmark.circle.fill", .red)
        }
        Image(systemName: symbol)
            .foregroundColor(color)
    }

    private func openInFinder(path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}
