//
//  BadgeResolverTests.swift
//  GitRDoneSharedTests
//

import XCTest
@testable import GitRDoneShared

final class BadgeResolverTests: XCTestCase {

    // MARK: - File Badges

    func test_fileBadge_nilStatus() {
        let result = BadgeResolver.badge(for: "file.txt", in: nil, isDirectory: false)
        XCTAssertEqual(result, "")
    }

    func test_fileBadge_unknownFile() {
        let status = RepoStatus(repoPath: "/repo", files: [:], timestamp: Date())
        let result = BadgeResolver.badge(for: "unknown.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "")
    }

    func test_fileBadge_untracked() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["file.txt": GitFileStatus(path: "file.txt", indexStatus: .untracked, worktreeStatus: .untracked)],
            timestamp: Date()
        )

        let result = BadgeResolver.badge(for: "file.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "Untracked")
    }

    func test_fileBadge_modified() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["file.txt": GitFileStatus(path: "file.txt", indexStatus: .clean, worktreeStatus: .modified)],
            timestamp: Date()
        )

        let result = BadgeResolver.badge(for: "file.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "Modified")
    }

    func test_fileBadge_staged() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["file.txt": GitFileStatus(path: "file.txt", indexStatus: .added, worktreeStatus: .clean)],
            timestamp: Date()
        )

        let result = BadgeResolver.badge(for: "file.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "Staged")
    }

    func test_fileBadge_conflict() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["file.txt": GitFileStatus(path: "file.txt", indexStatus: .unmerged, worktreeStatus: .unmerged)],
            timestamp: Date()
        )

        let result = BadgeResolver.badge(for: "file.txt", in: status, isDirectory: false)
        XCTAssertEqual(result, "Conflict")
    }

    // MARK: - Directory Badges

    func test_directoryBadge_empty() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: ["other/file.txt": GitFileStatus(path: "other/file.txt", indexStatus: .modified, worktreeStatus: .clean)],
            timestamp: Date()
        )

        let result = BadgeResolver.badge(for: "subdir", in: status, isDirectory: true)
        XCTAssertEqual(result, "")
    }

    func test_directoryBadge_aggregatesWorstStatus() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: [
                "subdir/clean.txt": GitFileStatus(path: "subdir/clean.txt", indexStatus: .clean, worktreeStatus: .clean),
                "subdir/modified.txt": GitFileStatus(path: "subdir/modified.txt", indexStatus: .clean, worktreeStatus: .modified),
                "subdir/untracked.txt": GitFileStatus(path: "subdir/untracked.txt", indexStatus: .untracked, worktreeStatus: .untracked)
            ],
            timestamp: Date()
        )

        let result = BadgeResolver.badge(for: "subdir", in: status, isDirectory: true)
        XCTAssertEqual(result, "Modified")
    }

    func test_directoryBadge_conflictWins() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: [
                "subdir/modified.txt": GitFileStatus(path: "subdir/modified.txt", indexStatus: .clean, worktreeStatus: .modified),
                "subdir/conflict.txt": GitFileStatus(path: "subdir/conflict.txt", indexStatus: .unmerged, worktreeStatus: .unmerged)
            ],
            timestamp: Date()
        )

        let result = BadgeResolver.badge(for: "subdir", in: status, isDirectory: true)
        XCTAssertEqual(result, "Conflict")
    }

    func test_rootDirectoryBadge() {
        let status = RepoStatus(
            repoPath: "/repo",
            files: [
                "file1.txt": GitFileStatus(path: "file1.txt", indexStatus: .untracked, worktreeStatus: .untracked),
                "subdir/file2.txt": GitFileStatus(path: "subdir/file2.txt", indexStatus: .clean, worktreeStatus: .modified)
            ],
            timestamp: Date()
        )

        let result = BadgeResolver.badge(for: "", in: status, isDirectory: true)
        XCTAssertEqual(result, "Modified")
    }
}
