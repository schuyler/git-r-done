//
//  RepoConfigurationTests.swift
//  GitRDoneSharedTests
//

import Testing
import Foundation
@testable import GitRDoneShared

/// In-memory implementation of RepoConfiguring for testing
private final class TestableRepoConfiguration: RepoConfiguring {
    private var _repositories: [WatchedRepository] = []

    var repositories: [WatchedRepository] {
        _repositories
    }

    func add(_ repo: WatchedRepository) {
        guard !_repositories.contains(where: { $0.path == repo.path }) else { return }
        _repositories.append(repo)
    }

    func remove(id: UUID) {
        _repositories.removeAll { $0.id == id }
    }

    func contains(path: String) -> Bool {
        let normalized = (path as NSString).standardizingPath
        return _repositories.contains { $0.path == normalized }
    }

    func updateDisplayName(id: UUID, name: String) {
        guard let index = _repositories.firstIndex(where: { $0.id == id }) else { return }
        var repo = _repositories[index]
        if name.isEmpty {
            // Revert to default (folder name)
            repo.displayName = URL(fileURLWithPath: repo.path).lastPathComponent
        } else {
            repo.displayName = name
        }
        _repositories[index] = repo
    }

    func repository(for path: String) -> WatchedRepository? {
        let normalized = (path as NSString).standardizingPath
        return _repositories.first { $0.path == normalized }
    }
}

@Suite("RepoConfiguration Tests")
struct RepoConfigurationTests {

    // MARK: - Basic Operations

    @Test("Add repository stores it")
    func addRepositoryStoresIt() {
        let config = TestableRepoConfiguration()
        let repo = WatchedRepository(path: "/test/repo", displayName: "Test Repo")

        config.add(repo)

        #expect(config.repositories.count == 1)
        #expect(config.repositories.first?.path == "/test/repo")
        #expect(config.repositories.first?.displayName == "Test Repo")
    }

    @Test("Contains returns true for added repository")
    func containsReturnsTrueForAddedRepo() {
        let config = TestableRepoConfiguration()
        config.add(WatchedRepository(path: "/test/repo"))

        #expect(config.contains(path: "/test/repo") == true)
        #expect(config.contains(path: "/other/repo") == false)
    }

    @Test("Remove by ID removes correct repository")
    func removeByIdRemovesCorrectRepo() {
        let config = TestableRepoConfiguration()
        let repo1 = WatchedRepository(path: "/repo1")
        let repo2 = WatchedRepository(path: "/repo2")
        config.add(repo1)
        config.add(repo2)

        config.remove(id: repo1.id)

        #expect(config.repositories.count == 1)
        #expect(config.repositories.first?.path == "/repo2")
    }

    // MARK: - updateDisplayName

    @Test("updateDisplayName changes the display name")
    func updateDisplayNameChangesName() {
        let config = TestableRepoConfiguration()
        let repo = WatchedRepository(path: "/test/repo", displayName: "Original Name")
        config.add(repo)

        config.updateDisplayName(id: repo.id, name: "New Name")

        #expect(config.repositories.first?.displayName == "New Name")
    }

    @Test("updateDisplayName with empty string reverts to folder name")
    func updateDisplayNameEmptyRevertsToFolderName() {
        let config = TestableRepoConfiguration()
        let repo = WatchedRepository(path: "/Users/test/my-project", displayName: "Custom Name")
        config.add(repo)

        config.updateDisplayName(id: repo.id, name: "")

        #expect(config.repositories.first?.displayName == "my-project")
    }

    @Test("updateDisplayName with non-existent ID does nothing")
    func updateDisplayNameNonExistentIdDoesNothing() {
        let config = TestableRepoConfiguration()
        let repo = WatchedRepository(path: "/test/repo", displayName: "Original")
        config.add(repo)

        config.updateDisplayName(id: UUID(), name: "New Name")

        #expect(config.repositories.first?.displayName == "Original")
    }

    @Test("updateDisplayName preserves other properties")
    func updateDisplayNamePreservesOtherProperties() {
        let config = TestableRepoConfiguration()
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1000)
        let repo = WatchedRepository(id: id, path: "/test/repo", displayName: "Original", dateAdded: date)
        config.add(repo)

        config.updateDisplayName(id: id, name: "New Name")

        let updated = config.repositories.first
        #expect(updated?.id == id)
        #expect(updated?.path == "/test/repo")
        #expect(updated?.dateAdded == date)
        #expect(updated?.displayName == "New Name")
    }

    // MARK: - repository(for:)

    @Test("repository(for:) returns matching repository")
    func repositoryForPathReturnsMatch() {
        let config = TestableRepoConfiguration()
        let repo = WatchedRepository(path: "/test/repo", displayName: "My Repo")
        config.add(repo)

        let found = config.repository(for: "/test/repo")

        #expect(found?.displayName == "My Repo")
        #expect(found?.id == repo.id)
    }

    @Test("repository(for:) returns nil when not found")
    func repositoryForPathReturnsNilWhenNotFound() {
        let config = TestableRepoConfiguration()
        config.add(WatchedRepository(path: "/test/repo"))

        let found = config.repository(for: "/other/repo")

        #expect(found == nil)
    }

    @Test("repository(for:) normalizes path before lookup")
    func repositoryForPathNormalizesPath() {
        let config = TestableRepoConfiguration()
        config.add(WatchedRepository(path: "/Users/test/repo"))

        // Should find even with non-normalized path (if standardizingPath normalizes it)
        let found = config.repository(for: "/Users/test/../test/repo")

        #expect(found != nil)
    }

    @Test("repository(for:) returns correct repo among multiple")
    func repositoryForPathReturnsCorrectAmongMultiple() {
        let config = TestableRepoConfiguration()
        config.add(WatchedRepository(path: "/repo1", displayName: "Repo One"))
        config.add(WatchedRepository(path: "/repo2", displayName: "Repo Two"))
        config.add(WatchedRepository(path: "/repo3", displayName: "Repo Three"))

        let found = config.repository(for: "/repo2")

        #expect(found?.displayName == "Repo Two")
    }
}
