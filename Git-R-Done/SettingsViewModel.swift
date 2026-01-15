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

    var repositories: [WatchedRepository] {
        repoConfiguration.repositories
    }

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
        errorPresenter: ErrorPresenting = AppleScriptDialogPresenter()
    ) {
        self.repoConfiguration = repoConfiguration
        self.settingsStore = settingsStore
        self.gitValidator = gitValidator
        self.errorPresenter = errorPresenter
    }

    func addRepository(url: URL) {
        let path = (url.path as NSString).standardizingPath

        // Check if already added
        if repoConfiguration.contains(path: path) {
            return
        }

        // Validate it's a git repository
        guard gitValidator.isGitRepository(at: path) else {
            errorPresenter.showError("The selected folder is not a Git repository.")
            return
        }

        let repo = WatchedRepository(path: path)
        repoConfiguration.add(repo)
    }

    func removeRepository(id: UUID) {
        // Get the path before removing so we can clean up the status cache
        if let repo = repoConfiguration.repositories.first(where: { $0.id == id }) {
            SharedStatusCache.shared.remove(path: repo.path)
        }
        repoConfiguration.remove(id: id)
    }

    /// Triggers a view refresh by updating an internal counter.
    /// Called when external notifications indicate data has changed.
    func refresh() {
        refreshTrigger += 1
    }

    // Internal counter to force @Observable to trigger updates
    // when underlying data sources change externally
    private var refreshTrigger: Int = 0
}
