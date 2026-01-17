//
//  SettingsViewModelTests.swift
//  Git-R-DoneTests
//

import Testing
import Foundation
@testable import Git_R_Done
@testable import GitRDoneShared

// MARK: - Mock Dependencies

private final class MockRepoConfiguration: RepoConfiguring {
    var repositories: [WatchedRepository] = []
    var addedRepos: [WatchedRepository] = []
    var removedIds: [UUID] = []
    var updatedDisplayNames: [(id: UUID, name: String)] = []

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

    func updateDisplayName(id: UUID, name: String) {
        updatedDisplayNames.append((id, name))
        if let index = repositories.firstIndex(where: { $0.id == id }) {
            var repo = repositories[index]
            repo.displayName = name.isEmpty ? URL(fileURLWithPath: repo.path).lastPathComponent : name
            repositories[index] = repo
        }
    }

    func repository(for path: String) -> WatchedRepository? {
        let normalized = (path as NSString).standardizingPath
        return repositories.first { $0.path == normalized }
    }
}

private final class MockSettingsStore: SettingsStoring {
    var settings: AppSettings = AppSettings()
    var updatedSettings: [AppSettings] = []

    func update(_ settings: AppSettings) {
        self.settings = settings
        updatedSettings.append(settings)
    }
}

private final class MockGitValidator: GitValidating {
    var validPaths: Set<String> = []

    func isGitRepository(at path: String) -> Bool {
        validPaths.contains(path)
    }
}

private final class MockErrorPresenter: ErrorPresenting {
    var shownErrors: [String] = []

    func showError(_ message: String) {
        shownErrors.append(message)
    }
}

private final class MockStatusCache: StatusCaching {
    var summaries: [RepoStatusSummary] = []
    var removedPaths: [String] = []

    func update(_ summary: RepoStatusSummary) {
        summaries.removeAll { $0.path == summary.path }
        summaries.append(summary)
    }

    func remove(path: String) {
        removedPaths.append(path)
        summaries.removeAll { $0.path == path }
    }

    func summary(for path: String) -> RepoStatusSummary? {
        summaries.first { $0.path == path }
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
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        let url = URL(fileURLWithPath: "/path/to/repo")
        viewModel.addRepositories(urls: [url])

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
            errorPresenter: errorPresenter,
            statusCache: MockStatusCache()
        )

        let url = URL(fileURLWithPath: "/not/a/repo")
        viewModel.addRepositories(urls: [url])

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
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        let url = URL(fileURLWithPath: "/existing/repo")
        viewModel.addRepositories(urls: [url])

        // Should not add duplicate
        #expect(repoConfig.addedRepos.isEmpty)
    }

    @Test("Removing a repository calls remove on configuration and cleans up status cache")
    func removeRepository() {
        let repoConfig = MockRepoConfiguration()
        let repo = WatchedRepository(path: "/path/to/repo")
        repoConfig.repositories = [repo]
        let statusCache = MockStatusCache()

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter(),
            statusCache: statusCache
        )

        viewModel.removeRepository(id: repo.id)

        #expect(repoConfig.removedIds.count == 1)
        #expect(repoConfig.removedIds.first == repo.id)
        #expect(statusCache.removedPaths.count == 1)
        #expect(statusCache.removedPaths.first == "/path/to/repo")
    }

    @Test("Toggling auto-push persists the setting")
    func toggleAutoPush() {
        let settingsStore = MockSettingsStore()
        settingsStore.settings = AppSettings(autoPushEnabled: false)

        let viewModel = SettingsViewModel(
            repoConfiguration: MockRepoConfiguration(),
            settingsStore: settingsStore,
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
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
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        #expect(viewModel.repositories.count == 2)
    }

    @Test("Refresh method can be called without error")
    func refreshDoesNotThrow() {
        let viewModel = SettingsViewModel(
            repoConfiguration: MockRepoConfiguration(),
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        // Should not throw or cause side effects
        viewModel.refresh()
        viewModel.refresh()
    }

    // MARK: - Multiple Repository Tests

    @Test("Adding multiple valid repositories succeeds")
    func addMultipleValidRepositories() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        gitValidator.validPaths = ["/repo1", "/repo2", "/repo3"]

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: gitValidator,
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        let urls = [
            URL(fileURLWithPath: "/repo1"),
            URL(fileURLWithPath: "/repo2"),
            URL(fileURLWithPath: "/repo3")
        ]
        viewModel.addRepositories(urls: urls)

        #expect(repoConfig.addedRepos.count == 3)
    }

    @Test("Adding mix of valid and invalid repositories shows single error")
    func addMixedRepositories() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        gitValidator.validPaths = ["/valid1", "/valid2"]
        let errorPresenter = MockErrorPresenter()

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: gitValidator,
            errorPresenter: errorPresenter,
            statusCache: MockStatusCache()
        )

        let urls = [
            URL(fileURLWithPath: "/valid1"),
            URL(fileURLWithPath: "/invalid1"),
            URL(fileURLWithPath: "/valid2"),
            URL(fileURLWithPath: "/invalid2")
        ]
        viewModel.addRepositories(urls: urls)

        #expect(repoConfig.addedRepos.count == 2)
        #expect(errorPresenter.shownErrors.count == 1)
        #expect(errorPresenter.shownErrors.first?.contains("invalid1") == true)
        #expect(errorPresenter.shownErrors.first?.contains("invalid2") == true)
    }

    @Test("Adding multiple invalid repositories shows batched error")
    func addMultipleInvalidRepositories() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        // No valid paths
        let errorPresenter = MockErrorPresenter()

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: gitValidator,
            errorPresenter: errorPresenter,
            statusCache: MockStatusCache()
        )

        let urls = [
            URL(fileURLWithPath: "/invalid1"),
            URL(fileURLWithPath: "/invalid2"),
            URL(fileURLWithPath: "/invalid3")
        ]
        viewModel.addRepositories(urls: urls)

        #expect(repoConfig.addedRepos.isEmpty)
        #expect(errorPresenter.shownErrors.count == 1)
        // Should contain "not Git repositories" (plural)
        #expect(errorPresenter.shownErrors.first?.contains("not Git repositories") == true)
    }

    @Test("Refresh updates repositories from configuration")
    func refreshUpdatesRepositories() {
        let repoConfig = MockRepoConfiguration()

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        #expect(viewModel.repositories.isEmpty)

        // Simulate external change to configuration
        repoConfig.repositories = [WatchedRepository(path: "/new/repo")]
        viewModel.refresh()

        #expect(viewModel.repositories.count == 1)
    }

    // MARK: - Display Name Tests

    @Test("updateDisplayName calls configuration method")
    func updateDisplayNameCallsConfiguration() {
        let repoConfig = MockRepoConfiguration()
        let repo = WatchedRepository(path: "/test/repo", displayName: "Original")
        repoConfig.repositories = [repo]

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        viewModel.updateDisplayName(for: repo.id, name: "New Name")

        #expect(repoConfig.updatedDisplayNames.count == 1)
        #expect(repoConfig.updatedDisplayNames.first?.id == repo.id)
        #expect(repoConfig.updatedDisplayNames.first?.name == "New Name")
    }

    @Test("updateDisplayName with empty string passes empty to configuration")
    func updateDisplayNameEmptyString() {
        let repoConfig = MockRepoConfiguration()
        let repo = WatchedRepository(path: "/test/my-project", displayName: "Custom")
        repoConfig.repositories = [repo]

        let viewModel = SettingsViewModel(
            repoConfiguration: repoConfig,
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        viewModel.updateDisplayName(for: repo.id, name: "")

        #expect(repoConfig.updatedDisplayNames.first?.name == "")
    }

    @Test("defaultDisplayName returns folder name when no gitOperations")
    func defaultDisplayNameFromFolderName() {
        let viewModel = SettingsViewModel(
            repoConfiguration: MockRepoConfiguration(),
            settingsStore: MockSettingsStore(),
            gitValidator: MockGitValidator(),
            errorPresenter: MockErrorPresenter(),
            statusCache: MockStatusCache()
        )

        let name = viewModel.defaultDisplayName(for: "/Users/test/my-awesome-project")

        #expect(name == "my-awesome-project")
    }
}
