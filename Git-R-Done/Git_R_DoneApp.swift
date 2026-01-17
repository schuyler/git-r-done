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
    private let gitValidator: GitValidating
    private let gitOperations: GitOperations
    private let errorPresenter: ErrorPresenting
    private var observers: [Any] = []

    var summaries: [RepoStatusSummary] = []

    init(
        repoConfiguration: RepoConfiguring = RepoConfiguration.shared,
        statusCache: StatusCaching = SharedStatusCache.shared,
        gitValidator: GitValidating = GitOperations(),
        gitOperations: GitOperations = GitOperations(),
        errorPresenter: ErrorPresenting = AppleScriptDialogPresenter()
    ) {
        self.repoConfiguration = repoConfiguration
        self.statusCache = statusCache
        self.gitValidator = gitValidator
        self.gitOperations = gitOperations
        self.errorPresenter = errorPresenter
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

    /// Returns the display name for a repository path.
    /// Looks up from configuration, falls back to folder name.
    func displayName(for path: String) -> String {
        repoConfiguration.repository(for: path)?.displayName
            ?? URL(fileURLWithPath: path).lastPathComponent
    }

    func addRepositories(urls: [URL]) {
        var invalidPaths: [String] = []

        for url in urls {
            let path = (url.path as NSString).standardizingPath

            // Skip if already added
            if repoConfiguration.contains(path: path) {
                continue
            }

            // Validate it's a git repository
            guard gitValidator.isGitRepository(at: path) else {
                invalidPaths.append(url.lastPathComponent)
                continue
            }

            // Derive display name from remote URL, fall back to folder name
            let displayName = defaultDisplayName(for: path)
            let repo = WatchedRepository(path: path, displayName: displayName)
            repoConfiguration.add(repo)
        }

        if !invalidPaths.isEmpty {
            let message = invalidPaths.count == 1
                ? "'\(invalidPaths[0])' is not a Git repository."
                : "The following folders are not Git repositories:\n\(invalidPaths.joined(separator: "\n"))"
            errorPresenter.showError(message)
        }

        // Refresh summaries after adding
        loadSummaries()
    }

    /// Returns the default display name for a path.
    /// Tries to derive from git remote URL, falls back to folder name.
    private func defaultDisplayName(for path: String) -> String {
        // Try to get the remote URL and parse the repo name from it
        if case .success(let remoteURL) = gitOperations.getRemoteURL(in: path),
           let url = remoteURL,
           let name = GitOperations.parseRepoName(from: url) {
            return name
        }
        // Fall back to folder name
        return URL(fileURLWithPath: path).lastPathComponent
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
                            Text(menuViewModel.displayName(for: summary.path))
                        }
                    }
                }
            }

            Divider()

            Button("+ Add Repository...") {
                showFolderPicker()
            }

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

    private func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select a Git repository folder"
        panel.prompt = "Add"

        if panel.runModal() == .OK {
            menuViewModel.addRepositories(urls: panel.urls)
        }
    }
}
