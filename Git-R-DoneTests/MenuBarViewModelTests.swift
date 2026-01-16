//
//  MenuBarViewModelTests.swift
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

private final class MockStatusCache: StatusCaching {
    var summaries: [RepoStatusSummary] = []

    func update(_ summary: RepoStatusSummary) {
        summaries.removeAll { $0.path == summary.path }
        summaries.append(summary)
    }

    func remove(path: String) {
        summaries.removeAll { $0.path == path }
    }

    func summary(for path: String) -> RepoStatusSummary? {
        summaries.first { $0.path == path }
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

// MARK: - Tests

@Suite("MenuBarViewModel Tests")
struct MenuBarViewModelTests {

    @Test("Empty repositories shows empty summaries")
    func emptyRepositories() {
        let repoConfig = MockRepoConfiguration()
        let statusCache = MockStatusCache()

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: statusCache
        )

        #expect(viewModel.summaries.isEmpty)
    }

    @Test("Repositories with cached status use cached status")
    func repositoriesWithCachedStatus() {
        let repoConfig = MockRepoConfiguration()
        repoConfig.repositories = [
            WatchedRepository(path: "/repo1"),
            WatchedRepository(path: "/repo2")
        ]

        let statusCache = MockStatusCache()
        statusCache.summaries = [
            RepoStatusSummary(path: "/repo1", status: .modified),
            RepoStatusSummary(path: "/repo2", status: .clean)
        ]

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: statusCache
        )

        #expect(viewModel.summaries.count == 2)
        #expect(viewModel.summaries.first { $0.path == "/repo1" }?.status == .modified)
        #expect(viewModel.summaries.first { $0.path == "/repo2" }?.status == .clean)
    }

    @Test("Repositories without cached status get pending status")
    func repositoriesWithoutCachedStatus() {
        let repoConfig = MockRepoConfiguration()
        repoConfig.repositories = [
            WatchedRepository(path: "/repo1"),
            WatchedRepository(path: "/repo2")
        ]

        let statusCache = MockStatusCache()
        // Only repo1 has cached status
        statusCache.summaries = [
            RepoStatusSummary(path: "/repo1", status: .ahead)
        ]

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: statusCache
        )

        #expect(viewModel.summaries.count == 2)
        #expect(viewModel.summaries.first { $0.path == "/repo1" }?.status == .ahead)
        #expect(viewModel.summaries.first { $0.path == "/repo2" }?.status == .pending)
    }

    @Test("All repositories without cache get pending status")
    func allRepositoriesWithoutCache() {
        let repoConfig = MockRepoConfiguration()
        repoConfig.repositories = [
            WatchedRepository(path: "/repo1"),
            WatchedRepository(path: "/repo2"),
            WatchedRepository(path: "/repo3")
        ]

        let statusCache = MockStatusCache()
        // No cached statuses

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: statusCache
        )

        #expect(viewModel.summaries.count == 3)
        #expect(viewModel.summaries.allSatisfy { $0.status == .pending })
    }

    @Test("loadSummaries refreshes from configuration")
    func loadSummariesRefreshes() {
        let repoConfig = MockRepoConfiguration()
        let statusCache = MockStatusCache()

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: statusCache
        )

        #expect(viewModel.summaries.isEmpty)

        // Simulate external change
        repoConfig.repositories = [WatchedRepository(path: "/new/repo")]
        viewModel.loadSummaries()

        #expect(viewModel.summaries.count == 1)
        #expect(viewModel.summaries.first?.path == "/new/repo")
    }

    @Test("Summaries preserve order from configuration")
    func summariesPreserveOrder() {
        let repoConfig = MockRepoConfiguration()
        repoConfig.repositories = [
            WatchedRepository(path: "/alpha"),
            WatchedRepository(path: "/beta"),
            WatchedRepository(path: "/gamma")
        ]

        let statusCache = MockStatusCache()

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: statusCache
        )

        #expect(viewModel.summaries.count == 3)
        #expect(viewModel.summaries[0].path == "/alpha")
        #expect(viewModel.summaries[1].path == "/beta")
        #expect(viewModel.summaries[2].path == "/gamma")
    }

    @Test("Cache entries not in configuration are ignored")
    func orphanedCacheEntriesIgnored() {
        let repoConfig = MockRepoConfiguration()
        repoConfig.repositories = [
            WatchedRepository(path: "/repo1")
        ]

        let statusCache = MockStatusCache()
        statusCache.summaries = [
            RepoStatusSummary(path: "/repo1", status: .clean),
            RepoStatusSummary(path: "/orphaned", status: .modified)
        ]

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: statusCache
        )

        // Should only show repo1, not orphaned
        #expect(viewModel.summaries.count == 1)
        #expect(viewModel.summaries.first?.path == "/repo1")
    }

    // MARK: - Add Repository Tests

    @Test("Adding a valid git repository succeeds")
    func addValidRepository() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        gitValidator.validPaths = ["/path/to/repo"]

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: MockStatusCache(),
            gitValidator: gitValidator,
            errorPresenter: MockErrorPresenter()
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

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: MockStatusCache(),
            gitValidator: gitValidator,
            errorPresenter: errorPresenter
        )

        let url = URL(fileURLWithPath: "/not/a/repo")
        viewModel.addRepositories(urls: [url])

        #expect(repoConfig.repositories.isEmpty)
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

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: MockStatusCache(),
            gitValidator: gitValidator,
            errorPresenter: MockErrorPresenter()
        )

        let url = URL(fileURLWithPath: "/existing/repo")
        viewModel.addRepositories(urls: [url])

        // Should not add duplicate (still just 1 repo)
        #expect(repoConfig.repositories.count == 1)
    }

    @Test("Adding multiple valid repositories succeeds")
    func addMultipleValidRepositories() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        gitValidator.validPaths = ["/repo1", "/repo2", "/repo3"]

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: MockStatusCache(),
            gitValidator: gitValidator,
            errorPresenter: MockErrorPresenter()
        )

        let urls = [
            URL(fileURLWithPath: "/repo1"),
            URL(fileURLWithPath: "/repo2"),
            URL(fileURLWithPath: "/repo3")
        ]
        viewModel.addRepositories(urls: urls)

        #expect(repoConfig.addedRepos.count == 3)
    }

    @Test("Adding mix of valid and invalid shows batched error")
    func addMixedRepositories() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        gitValidator.validPaths = ["/valid1", "/valid2"]
        let errorPresenter = MockErrorPresenter()

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: MockStatusCache(),
            gitValidator: gitValidator,
            errorPresenter: errorPresenter
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

    @Test("Adding multiple invalid repositories shows plural error message")
    func addMultipleInvalidRepositories() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        // No valid paths
        let errorPresenter = MockErrorPresenter()

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: MockStatusCache(),
            gitValidator: gitValidator,
            errorPresenter: errorPresenter
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

    @Test("Summaries update after adding repository")
    func summariesUpdateAfterAdd() {
        let repoConfig = MockRepoConfiguration()
        let gitValidator = MockGitValidator()
        gitValidator.validPaths = ["/new/repo"]

        let viewModel = MenuBarViewModel(
            repoConfiguration: repoConfig,
            statusCache: MockStatusCache(),
            gitValidator: gitValidator,
            errorPresenter: MockErrorPresenter()
        )

        #expect(viewModel.summaries.isEmpty)

        let url = URL(fileURLWithPath: "/new/repo")
        viewModel.addRepositories(urls: [url])

        #expect(viewModel.summaries.count == 1)
        #expect(viewModel.summaries.first?.path == "/new/repo")
        #expect(viewModel.summaries.first?.status == .pending)
    }
}
