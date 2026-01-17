//
//  SettingsViewModel.swift
//  Git-R-Done
//

import Foundation
import GitRDoneShared

@Observable
final class SettingsViewModel {

    private let repoConfiguration: RepoConfiguring
    private let settingsStore: SettingsStoring
    private let gitValidator: GitValidating
    private let errorPresenter: ErrorPresenting
    private let statusCache: StatusCaching

    var repositories: [WatchedRepository] = []

    var autoPushEnabled: Bool {
        get {
            settingsStore.settings.autoPushEnabled
        }
        set {
            var updated = settingsStore.settings
            updated.autoPushEnabled = newValue
            settingsStore.update(updated)
        }
    }

    init(
        repoConfiguration: RepoConfiguring = RepoConfiguration.shared,
        settingsStore: SettingsStoring = SettingsStore.shared,
        gitValidator: GitValidating = GitOperations(),
        errorPresenter: ErrorPresenting = AppleScriptDialogPresenter(),
        statusCache: StatusCaching = SharedStatusCache.shared
    ) {
        self.repoConfiguration = repoConfiguration
        self.settingsStore = settingsStore
        self.gitValidator = gitValidator
        self.errorPresenter = errorPresenter
        self.statusCache = statusCache
        self.repositories = repoConfiguration.repositories
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

            let repo = WatchedRepository(path: path)
            repoConfiguration.add(repo)
        }

        if !invalidPaths.isEmpty {
            let message = invalidPaths.count == 1
                ? "'\(invalidPaths[0])' is not a Git repository."
                : "The following folders are not Git repositories:\n\(invalidPaths.joined(separator: "\n"))"
            errorPresenter.showError(message)
        }
    }

    func removeRepository(id: UUID) {
        // Get the path before removing so we can clean up the status cache
        if let repo = repoConfiguration.repositories.first(where: { $0.id == id }) {
            statusCache.remove(path: repo.path)
        }
        repoConfiguration.remove(id: id)
    }

    /// Updates the display name for a repository.
    /// Pass an empty string to revert to the default (folder name).
    func updateDisplayName(for id: UUID, name: String) {
        repoConfiguration.updateDisplayName(id: id, name: name)
    }

    /// Returns the default display name for a path.
    /// Tries to derive from git remote URL, falls back to folder name.
    func defaultDisplayName(for path: String) -> String {
        // For now, just return the folder name
        // In the future, this could fetch the remote URL and parse it
        URL(fileURLWithPath: path).lastPathComponent
    }

    /// Reloads data from underlying stores.
    /// Called when external notifications indicate data has changed.
    func refresh() {
        repositories = repoConfiguration.repositories
    }
}
