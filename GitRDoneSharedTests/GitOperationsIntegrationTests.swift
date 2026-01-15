//
//  GitOperationsIntegrationTests.swift
//  GitRDoneSharedTests
//
//  Integration tests for GitOperations using real git commands
//

import XCTest
@testable import GitRDoneShared

final class GitOperationsIntegrationTests: XCTestCase {

    var testRepoPath: String!
    var gitOps: GitOperations!

    override func setUp() {
        super.setUp()
        gitOps = GitOperations(executor: ShellGitExecutor())

        guard gitOps.isGitAvailable() else {
            XCTFail("Git not available")
            return
        }

        testRepoPath = createTestRepository()
    }

    override func tearDown() {
        if let path = testRepoPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        super.tearDown()
    }

    private func createTestRepository() -> String {
        let tempDir = NSTemporaryDirectory()
        let repoPath = (tempDir as NSString).appendingPathComponent(UUID().uuidString)

        try? FileManager.default.createDirectory(atPath: repoPath, withIntermediateDirectories: true)

        let executor = ShellGitExecutor()
        _ = executor.execute(["init"], in: repoPath, timeout: 10)
        _ = executor.execute(["config", "user.email", "test@example.com"], in: repoPath, timeout: 5)
        _ = executor.execute(["config", "user.name", "Test User"], in: repoPath, timeout: 5)

        return repoPath
    }

    private func createFile(_ name: String, content: String = "test") {
        let path = (testRepoPath as NSString).appendingPathComponent(name)
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    /// Helper to find a file status by path in the status array
    private func findStatus(_ filename: String, in statuses: [GitFileStatus]) -> GitFileStatus? {
        statuses.first { $0.path == filename }
    }

    // MARK: - Tests

    func test_isGitRepository() {
        XCTAssertTrue(gitOps.isGitRepository(at: testRepoPath))
        XCTAssertFalse(gitOps.isGitRepository(at: NSTemporaryDirectory()))
    }

    func test_status_detectsUntracked() {
        createFile("untracked.txt")

        let result = gitOps.getStatus(in: testRepoPath)
        guard case .success(let statuses) = result else {
            XCTFail("Expected success")
            return
        }

        let fileStatus = findStatus("untracked.txt", in: statuses)
        XCTAssertNotNil(fileStatus, "Expected to find untracked.txt in status")
        XCTAssertTrue(fileStatus?.isUntracked ?? false, "Expected file to be untracked")
    }

    func test_stageAndStatus() {
        createFile("staged.txt")
        _ = gitOps.stage(file: "staged.txt", in: testRepoPath)

        let result = gitOps.getStatus(in: testRepoPath)
        guard case .success(let statuses) = result else {
            XCTFail("Expected success")
            return
        }

        let fileStatus = findStatus("staged.txt", in: statuses)
        XCTAssertNotNil(fileStatus, "Expected to find staged.txt in status")
        XCTAssertTrue(fileStatus?.isStaged ?? false, "Expected file to be staged")
    }

    func test_fullWorkflow() {
        // 1. Create and verify untracked
        createFile("workflow.txt", content: "initial")
        var result = gitOps.getStatus(in: testRepoPath)
        var statuses = try! result.get()
        var fileStatus = findStatus("workflow.txt", in: statuses)
        XCTAssertTrue(fileStatus?.isUntracked ?? false, "Step 1: Expected file to be untracked")

        // 2. Stage and verify
        _ = gitOps.stage(file: "workflow.txt", in: testRepoPath)
        result = gitOps.getStatus(in: testRepoPath)
        statuses = try! result.get()
        fileStatus = findStatus("workflow.txt", in: statuses)
        XCTAssertTrue(fileStatus?.isStaged ?? false, "Step 2: Expected file to be staged")

        // 3. Commit and verify clean
        _ = gitOps.commit(message: "Add workflow.txt", in: testRepoPath)
        result = gitOps.getStatus(in: testRepoPath)
        statuses = try! result.get()
        fileStatus = findStatus("workflow.txt", in: statuses)
        XCTAssertNil(fileStatus, "Step 3: Expected file to not appear in status after commit (clean)")

        // 4. Modify and verify
        createFile("workflow.txt", content: "modified")
        result = gitOps.getStatus(in: testRepoPath)
        statuses = try! result.get()
        fileStatus = findStatus("workflow.txt", in: statuses)
        XCTAssertTrue(fileStatus?.isModified ?? false, "Step 4: Expected file to be modified")
    }

    func test_unstage_newFile() {
        // Create and stage a NEW file (never committed)
        createFile("tounstage.txt")
        _ = gitOps.stage(file: "tounstage.txt", in: testRepoPath)

        // Verify it's staged
        var result = gitOps.getStatus(in: testRepoPath)
        var statuses = try! result.get()
        var fileStatus = findStatus("tounstage.txt", in: statuses)
        XCTAssertTrue(fileStatus?.isStaged ?? false, "Expected file to be staged before unstage")

        // Unstage
        let unstageResult = gitOps.unstage(file: "tounstage.txt", in: testRepoPath)
        XCTAssertNoThrow(try unstageResult.get(), "Unstage should succeed")

        // Verify it's now untracked (not staged)
        result = gitOps.getStatus(in: testRepoPath)
        statuses = try! result.get()
        fileStatus = findStatus("tounstage.txt", in: statuses)
        XCTAssertTrue(fileStatus?.isUntracked ?? false, "Expected file to be untracked after unstage")
    }

    func test_unstage_modifiedFile() {
        // Create, stage, and commit a file first
        createFile("existingfile.txt", content: "original")
        _ = gitOps.stage(file: "existingfile.txt", in: testRepoPath)
        _ = gitOps.commit(message: "Initial commit", in: testRepoPath)

        // Modify and stage the changes
        createFile("existingfile.txt", content: "modified")
        _ = gitOps.stage(file: "existingfile.txt", in: testRepoPath)

        // Verify it's staged
        var result = gitOps.getStatus(in: testRepoPath)
        var statuses = try! result.get()
        var fileStatus = findStatus("existingfile.txt", in: statuses)
        XCTAssertTrue(fileStatus?.isStaged ?? false, "Expected file to be staged before unstage")

        // Unstage
        let unstageResult = gitOps.unstage(file: "existingfile.txt", in: testRepoPath)
        XCTAssertNoThrow(try unstageResult.get(), "Unstage should succeed")

        // Verify it's now just modified in worktree (not staged)
        result = gitOps.getStatus(in: testRepoPath)
        statuses = try! result.get()
        fileStatus = findStatus("existingfile.txt", in: statuses)
        XCTAssertNotNil(fileStatus, "Expected file to appear in status")
        XCTAssertFalse(fileStatus?.isStaged ?? true, "Expected file to NOT be staged after unstage")
        XCTAssertTrue(fileStatus?.isModified ?? false, "Expected file to be modified after unstage")
    }

    func test_revert() {
        // Create, stage, and commit a file
        createFile("torevert.txt", content: "original")
        _ = gitOps.stage(file: "torevert.txt", in: testRepoPath)
        _ = gitOps.commit(message: "Initial commit", in: testRepoPath)

        // Modify the file
        createFile("torevert.txt", content: "modified")

        // Verify it's modified
        var result = gitOps.getStatus(in: testRepoPath)
        var statuses = try! result.get()
        var fileStatus = findStatus("torevert.txt", in: statuses)
        XCTAssertTrue(fileStatus?.isModified ?? false, "Expected file to be modified before revert")

        // Revert
        let revertResult = gitOps.revert(file: "torevert.txt", in: testRepoPath)
        XCTAssertNoThrow(try revertResult.get(), "Revert should succeed")

        // Verify it's now clean
        result = gitOps.getStatus(in: testRepoPath)
        statuses = try! result.get()
        fileStatus = findStatus("torevert.txt", in: statuses)
        XCTAssertNil(fileStatus, "Expected file to not appear in status after revert (clean)")

        // Verify content is reverted
        let path = (testRepoPath as NSString).appendingPathComponent("torevert.txt")
        let content = try? String(contentsOfFile: path, encoding: .utf8)
        XCTAssertEqual(content, "original", "Expected content to be reverted to original")
    }

    func test_commitFile() {
        // Create two files
        createFile("file1.txt", content: "content1")
        createFile("file2.txt", content: "content2")

        // Commit only file1
        let commitResult = gitOps.commitFile("file1.txt", message: "Commit file1 only", in: testRepoPath)
        XCTAssertNoThrow(try commitResult.get(), "commitFile should succeed")

        // Verify file1 is committed (not in status) but file2 is still untracked
        let result = gitOps.getStatus(in: testRepoPath)
        let statuses = try! result.get()

        let file1Status = findStatus("file1.txt", in: statuses)
        XCTAssertNil(file1Status, "Expected file1.txt to not appear in status after commit")

        let file2Status = findStatus("file2.txt", in: statuses)
        XCTAssertTrue(file2Status?.isUntracked ?? false, "Expected file2.txt to still be untracked")
    }

    func test_commitAll() {
        // Create multiple files
        createFile("all1.txt", content: "content1")
        createFile("all2.txt", content: "content2")
        createFile("subdir/all3.txt", content: "content3")

        // Commit all
        let commitResult = gitOps.commitAll(message: "Commit all files", in: testRepoPath)
        XCTAssertNoThrow(try commitResult.get(), "commitAll should succeed")

        // Verify all files are committed (status is empty)
        let result = gitOps.getStatus(in: testRepoPath)
        let statuses = try! result.get()
        XCTAssertTrue(statuses.isEmpty, "Expected no files in status after commitAll")
    }

    func test_getRepoName() {
        let name = gitOps.getRepoName(at: testRepoPath)
        // The repo name should be the UUID we created it with
        XCTAssertFalse(name.isEmpty, "Expected non-empty repo name")
        XCTAssertTrue(testRepoPath.hasSuffix(name), "Expected repo name to match directory name")
    }

    func test_status_errorForNonExistentPath() {
        let result = gitOps.getStatus(in: "/nonexistent/path/to/repo")

        guard case .failure(let error) = result else {
            XCTFail("Expected failure for non-existent path")
            return
        }

        if case .repoNotAccessible(_) = error {
            // Expected
        } else {
            XCTFail("Expected repoNotAccessible error, got \(error)")
        }
    }

    func test_status_errorForNonRepository() {
        // Create a directory that is not a git repo
        let tempDir = NSTemporaryDirectory()
        let nonRepoPath = (tempDir as NSString).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(atPath: nonRepoPath, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(atPath: nonRepoPath)
        }

        let result = gitOps.getStatus(in: nonRepoPath)

        guard case .failure(let error) = result else {
            XCTFail("Expected failure for non-repository")
            return
        }

        if case .notARepository = error {
            // Expected
        } else {
            XCTFail("Expected notARepository error, got \(error)")
        }
    }

    func test_status_detectsDeleted() {
        // Create, stage, and commit a file
        createFile("todelete.txt", content: "content")
        _ = gitOps.stage(file: "todelete.txt", in: testRepoPath)
        _ = gitOps.commit(message: "Add file to delete", in: testRepoPath)

        // Delete the file
        let path = (testRepoPath as NSString).appendingPathComponent("todelete.txt")
        try? FileManager.default.removeItem(atPath: path)

        // Verify it's detected as deleted
        let result = gitOps.getStatus(in: testRepoPath)
        let statuses = try! result.get()
        let fileStatus = findStatus("todelete.txt", in: statuses)

        XCTAssertNotNil(fileStatus, "Expected to find deleted file in status")
        XCTAssertEqual(fileStatus?.worktreeStatus, .deleted, "Expected worktree status to be deleted")
    }
}
