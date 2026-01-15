//
//  GitOperationsTests.swift
//  GitRDoneSharedTests
//

import XCTest
@testable import GitRDoneShared

final class GitOperationsTests: XCTestCase {

    var mockExecutor: MockGitExecutor!
    var gitOps: GitOperations!

    override func setUp() {
        super.setUp()
        mockExecutor = MockGitExecutor()
        gitOps = GitOperations(executor: mockExecutor)
    }

    // MARK: - Availability

    func test_isGitAvailable_delegatesToExecutor() {
        mockExecutor.isGitAvailableResult = false
        XCTAssertFalse(gitOps.isGitAvailable())

        mockExecutor.isGitAvailableResult = true
        XCTAssertTrue(gitOps.isGitAvailable())
    }

    func test_status_returnsGitNotInstalled_whenUnavailable() {
        mockExecutor.isGitAvailableResult = false

        let result = gitOps.status(for: "/repo")

        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(error, .gitNotInstalled)
    }

    // MARK: - isGitRepository

    func test_isGitRepository_returnsTrue_whenSuccess() {
        mockExecutor.stub(["rev-parse", "--git-dir"], result: .success(".git"))

        XCTAssertTrue(gitOps.isGitRepository(at: "/path/to/repo"))
    }

    func test_isGitRepository_returnsFalse_whenFailure() {
        mockExecutor.stub(["rev-parse", "--git-dir"], result: .failure("fatal: not a git repository"))

        XCTAssertFalse(gitOps.isGitRepository(at: "/path/to/not-repo"))
    }

    // MARK: - status

    func test_status_parsesOutput() {
        mockExecutor.stubStatus("? untracked.txt\n1 .M N... 100644 100644 100644 abc def modified.txt")

        let result = gitOps.status(for: "/repo")

        guard case .success(let status) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(status.files.count, 2)
    }

    func test_status_returnsTimedOut() {
        mockExecutor.stub(["status", "--porcelain=v2", "--branch"], result: .timedOut)

        let result = gitOps.status(for: "/repo")

        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(error, .timedOut)
    }

    // MARK: - stage

    func test_stage_executesCorrectCommand() {
        mockExecutor.stub(["add", "--", "file.txt"], result: .success())

        _ = gitOps.stage(file: "file.txt", in: "/repo")

        XCTAssertEqual(mockExecutor.executedCommands.count, 1)
        XCTAssertEqual(mockExecutor.executedCommands[0].arguments, ["add", "--", "file.txt"])
        XCTAssertEqual(mockExecutor.executedCommands[0].directory, "/repo")
    }

    // MARK: - commit

    func test_commit_executesWithMessage() {
        mockExecutor.stub(["commit", "-m", "My commit message"], result: .success())

        _ = gitOps.commit(message: "My commit message", in: "/repo")

        XCTAssertEqual(mockExecutor.executedCommands.last?.arguments, ["commit", "-m", "My commit message"])
    }

    // MARK: - pull

    func test_pull_returnsSuccess() {
        mockExecutor.stub(["rev-parse", "HEAD"], result: .success("abc123"))
        mockExecutor.stubPull(" file1.txt | 5 +++++\n file2.txt | 3 +++")
        mockExecutor.stub(["diff", "--name-only", "abc123", "HEAD"], result: .success("file1.txt\nfile2.txt"))

        let result = gitOps.pull(in: "/repo")

        guard case .success(let pullResult) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertTrue(pullResult.success)
        XCTAssertEqual(pullResult.updatedFiles, ["file1.txt", "file2.txt"])
    }

    func test_pull_detectsConflicts() {
        mockExecutor.stub(["rev-parse", "HEAD"], result: .success("abc123"))
        mockExecutor.stub(["pull"], result: ShellResult(
            exitCode: 1,
            stdout: "CONFLICT (content): Merge conflict in file1.txt\nCONFLICT (content): Merge conflict in file2.txt",
            stderr: ""
        ))

        let result = gitOps.pull(in: "/repo")

        guard case .success(let pullResult) = result else {
            XCTFail("Expected success with conflicts")
            return
        }

        XCTAssertFalse(pullResult.success)
        XCTAssertEqual(pullResult.conflicts, ["file1.txt", "file2.txt"])
    }

    // MARK: - acceptTheirs

    func test_acceptTheirs_executesCheckoutThenAdd() {
        mockExecutor.stub(["checkout", "--theirs", "--", "file.txt"], result: .success())
        mockExecutor.stub(["add", "--", "file.txt"], result: .success())

        let result = gitOps.acceptTheirs(file: "file.txt", in: "/repo")

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(mockExecutor.executedCommands.count, 2)
        XCTAssertEqual(mockExecutor.executedCommands[0].arguments, ["checkout", "--theirs", "--", "file.txt"])
        XCTAssertEqual(mockExecutor.executedCommands[1].arguments, ["add", "--", "file.txt"])
    }
}

extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
