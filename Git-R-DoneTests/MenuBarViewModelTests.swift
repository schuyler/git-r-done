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

    func add(_ repo: WatchedRepository) {
        repositories.append(repo)
    }

    func remove(id: UUID) {
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
}
