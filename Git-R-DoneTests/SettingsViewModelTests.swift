//
//  SettingsViewModelTests.swift
//  Git-R-DoneTests
//

import Testing
import Foundation
@testable import Git_R_Done
@testable import GitRDoneShared

// MARK: - Mock Dependencies

final class MockRepoConfiguration: RepoConfiguring {
    var repositories: [WatchedRepository] = []
    var addedRepos: [WatchedRepository] = []
    var removedIds: [UUID] = []

    func add(_ repo: WatchedRepository) {
        addedRepos.append(repo)
        repositories.append(repo)
    }

    func remove(id: UUID) {
        removedIds.append(id)
        repositories.removeAll { $0.id == id }
    }

    func contains(path: String) -> Bool {
        repositories.contains { $0.path == path }
    }
}

final class MockSettingsStore: SettingsStoring {
    var settings: AppSettings = AppSettings()
    var updatedSettings: [AppSettings] = []

    func update(_ settings: AppSettings) {
        self.settings = settings
        updatedSettings.append(settings)
    }
}

final class MockGitValidator: GitValidating {
    var validPaths: Set<String> = []

    func isGitRepository(at path: String) -> Bool {
        validPaths.contains(path)
    }
}

final class MockErrorPresenter: ErrorPresenting {
    var shownErrors: [String] = []

    func showError(_ message: String) {
        shownErrors.append(message)
    }
}

// MARK: - Tests

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {

    @Test("Adding a valid git repository succeeds")
    func addValidRepository() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        gitValidator.validPaths = ["/path/to/repo"]

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: gitValidator,
            errorPresenter: MockErrorPresenter()
        )

        let url = URL(fileURLWithPath: "/path/to/repo")
        viewModel.addRepository(url: url)

        #expect(repoConfig.addedRepos.count == 1)
        #expect(repoConfig.addedRepos.first?.path == "/path/to/repo")
    }

    @Test("Adding a non-git folder shows error")
    func addInvalidRepository() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        // validPaths is empty - no valid git repos
        let errorPresenter = MockErrorPresenter()

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: gitValidator,
            errorPresenter: errorPresenter
        )

        let url = URL(fileURLWithPath: "/not/a/repo")
        viewModel.addRepository(url: url)

        #expect(repoConfig.addedRepos.isEmpty)
        #expect(errorPresenter.shownErrors.count == 1)
        #expect(errorPresenter.shownErrors.first?.contains("not a Git repository") == true)
    }

    @Test("Adding a duplicate repository is ignored")
    func addDuplicateRepository() {
        let repoConfig = MockRepoConfiguration()
        let existingRepo = WatchedRepository(path: "/existing/repo")
        repoConfig.repositories = [existingRepo]

        let gitValidator = MockGitValidator()
        gitValidator.validPaths = ["/existing/repo"]

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: gitValidator,
            errorPresenter: MockErrorPresenter()
        )

        let url = URL(fileURLWithPath: "/existing/repo")
        viewModel.addRepository(url: url)

        // Should not add duplicate
        #expect(repoConfig.addedRepos.isEmpty)
    }

    @Test("Removing a repository calls remove on configuration")
    func removeRepository() {
        let repoConfig = MockRepoConfiguration()
        let repo = WatchedRepository(path: "/path/to/repo")
        repoConfig.repositories = [repo]

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter()
        )

        viewModel.removeRepository(id: repo.id)

        #expect(repoConfig.removedIds.count == 1)
        #expect(repoConfig.removedIds.first == repo.id)
    }

    @Test("Toggling auto-push persists the setting")
    func toggleAutoPush() {
        let settingsStore = MockSettingsStore()
        settingsStore.settings = AppSettings(autoPushEnabled: false)

        let viewModel = SettingsViewModel(
            repoConfiguration: MockRepoConfiguration(),
            settingsStore: settingsStore,
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter()
        )

        #expect(viewModel.autoPushEnabled == false)

        viewModel.autoPushEnabled = true

        #expect(settingsStore.updatedSettings.count == 1)
        #expect(settingsStore.updatedSettings.first?.autoPushEnabled == true)
    }

    @Test("Repositories property reflects configuration")
    func repositoriesReflectsConfiguration() {
        let repoConfig = MockRepoConfiguration()
        let repo1 = WatchedRepository(path: "/repo1")
        let repo2 = WatchedRepository(path: "/repo2")
        repoConfig.repositories = [repo1, repo2]

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter()
        )

        #expect(viewModel.repositories.count == 2)
    }

    @Test("Refresh method can be called without error")
    func refreshDoesNotThrow() {
        let viewModel = SettingsViewModel(
            repoConfiguration: MockRepoConfiguration(),
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter()
        )

        // Should not throw or cause side effects
        viewModel.refresh()
        viewModel.refresh()
    }
}
