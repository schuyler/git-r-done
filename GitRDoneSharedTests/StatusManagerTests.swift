//
//  StatusManagerTests.swift
//  GitRDoneSharedTests
//
//  Unit tests for StatusManager per TRD Section 11.5
//

import XCTest
@testable import GitRDoneShared

final class StatusManagerTests: XCTestCase {

    // MARK: - makeRelativePath

    func test_makeRelativePath_basic() {
        let result = StatusManager.makeRelativePath("/repo/subdir/file.txt", relativeTo: "/repo")
        XCTAssertEqual(result, "subdir/file.txt")
    }

    func test_makeRelativePath_rootFile() {
        let result = StatusManager.makeRelativePath("/repo/file.txt", relativeTo: "/repo")
        XCTAssertEqual(result, "file.txt")
    }

    func test_makeRelativePath_notRelated() {
        let result = StatusManager.makeRelativePath("/other/file.txt", relativeTo: "/repo")
        XCTAssertEqual(result, "/other/file.txt")
    }

    func test_makeRelativePath_exactMatch() {
        let result = StatusManager.makeRelativePath("/repo", relativeTo: "/repo")
        XCTAssertEqual(result, "")
    }
}
