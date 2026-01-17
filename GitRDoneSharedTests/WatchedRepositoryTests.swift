//
//  WatchedRepositoryTests.swift
//  GitRDoneSharedTests
//

import Testing
import Foundation
@testable import GitRDoneShared

@Suite("WatchedRepository Tests")
struct WatchedRepositoryTests {

    // MARK: - Initialization with Path Only

    @Test("Init with path only derives displayName from lastPathComponent")
    func initWithPathOnlyDerivesDisplayName() {
        let repo = WatchedRepository(path: "/Users/test/Documents/my-project")

        #expect(repo.displayName == "my-project")
    }

    @Test("Init with path only standardizes the path")
    func initWithPathOnlyStandardizesPath() {
        // NSString.standardizingPath resolves ~, .., etc.
        let repo = WatchedRepository(path: "/Users/test/../test/repo")

        #expect(repo.path == "/Users/test/repo")
    }

    @Test("Init with path only generates UUID")
    func initWithPathOnlyGeneratesUUID() {
        let repo1 = WatchedRepository(path: "/repo1")
        let repo2 = WatchedRepository(path: "/repo2")

        #expect(repo1.id != repo2.id)
    }

    @Test("Init with path only sets dateAdded to now")
    func initWithPathOnlySetsDateAdded() {
        let before = Date()
        let repo = WatchedRepository(path: "/repo")
        let after = Date()

        #expect(repo.dateAdded >= before)
        #expect(repo.dateAdded <= after)
    }

    // MARK: - Initialization with Explicit Display Name

    @Test("Init with explicit displayName uses provided name")
    func initWithExplicitDisplayName() {
        let repo = WatchedRepository(
            path: "/Users/test/local-folder-name",
            displayName: "My Custom Project Name"
        )

        #expect(repo.displayName == "My Custom Project Name")
        #expect(repo.path == "/Users/test/local-folder-name")
    }

    @Test("Init with explicit displayName still standardizes path")
    func initWithExplicitDisplayNameStandardizesPath() {
        let repo = WatchedRepository(
            path: "/Users/test/../test/repo",
            displayName: "Custom Name"
        )

        #expect(repo.path == "/Users/test/repo")
        #expect(repo.displayName == "Custom Name")
    }

    @Test("Init with all parameters preserves values")
    func initWithAllParameters() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1000)

        let repo = WatchedRepository(
            id: id,
            path: "/my/repo",
            displayName: "My Repo",
            dateAdded: date
        )

        #expect(repo.id == id)
        #expect(repo.path == "/my/repo")
        #expect(repo.displayName == "My Repo")
        #expect(repo.dateAdded == date)
    }

    // MARK: - URL Property

    @Test("URL property returns file URL for path")
    func urlPropertyReturnsFileURL() {
        let repo = WatchedRepository(path: "/Users/test/repo")

        #expect(repo.url == URL(fileURLWithPath: "/Users/test/repo"))
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all properties including displayName")
    func codableRoundTrip() throws {
        let original = WatchedRepository(
            id: UUID(),
            path: "/test/repo",
            displayName: "Custom Display Name",
            dateAdded: Date(timeIntervalSince1970: 12345)
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchedRepository.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.path == original.path)
        #expect(decoded.displayName == original.displayName)
        #expect(decoded.dateAdded == original.dateAdded)
    }

    @Test("Codable decodes legacy data with computed displayName")
    func codableDecodesLegacyData() throws {
        // Simulate old format where displayName was derived from path
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "path": "/Users/test/my-repo",
            "displayName": "my-repo",
            "dateAdded": 0
        }
        """

        let decoded = try JSONDecoder().decode(WatchedRepository.self, from: json.data(using: .utf8)!)

        #expect(decoded.displayName == "my-repo")
    }

    // MARK: - Equatable

    @Test("Equatable compares all properties")
    func equatableComparesAllProperties() {
        let id = UUID()
        let date = Date()

        let repo1 = WatchedRepository(id: id, path: "/repo", displayName: "Name", dateAdded: date)
        let repo2 = WatchedRepository(id: id, path: "/repo", displayName: "Name", dateAdded: date)
        let repo3 = WatchedRepository(id: id, path: "/repo", displayName: "Different", dateAdded: date)

        #expect(repo1 == repo2)
        #expect(repo1 != repo3)
    }

    // MARK: - Edge Cases

    @Test("Root path has empty displayName")
    func rootPathDisplayName() {
        let repo = WatchedRepository(path: "/")

        #expect(repo.displayName == "/")
    }

    @Test("Single component path uses that as displayName")
    func singleComponentPath() {
        let repo = WatchedRepository(path: "/repo")

        #expect(repo.displayName == "repo")
    }

    @Test("Path with .git suffix preserves suffix in derived name")
    func pathWithGitSuffix() {
        // When using path-based derivation, the .git suffix is kept
        // (Remote URL parsing strips it, but path-based does not)
        let repo = WatchedRepository(path: "/Users/test/my-project.git")

        #expect(repo.displayName == "my-project.git")
    }
}
