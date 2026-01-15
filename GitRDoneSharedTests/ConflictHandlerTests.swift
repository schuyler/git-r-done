//
//  ConflictHandlerTests.swift
//  GitRDoneSharedTests
//

import XCTest
@testable import GitRDoneShared

final class ConflictHandlerTests: XCTestCase {

    var mockExecutor: MockGitExecutor!
    var gitOps: GitOperations!
    var handler: ConflictHandler!
    var tempDir: String!

    override func setUp() {
        super.setUp()
        mockExecutor = MockGitExecutor()
        gitOps = GitOperations(executor: mockExecutor)
        handler = ConflictHandler(gitOps: gitOps)

        // Create temp directory for file operations
        tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        super.tearDown()
    }

    // MARK: - generateBackupName

    func test_generateBackupName_simple() {
        let result = handler.generateBackupName(for: "document.xlsx", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "document (Conflict 2025-01-14 15.30.45).xlsx")
    }

    func test_generateBackupName_withSubdirectory() {
        let result = handler.generateBackupName(for: "path/to/document.xlsx", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "path/to/document (Conflict 2025-01-14 15.30.45).xlsx")
    }

    func test_generateBackupName_noExtension() {
        let result = handler.generateBackupName(for: "Makefile", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "Makefile (Conflict 2025-01-14 15.30.45)")
    }

    func test_generateBackupName_multipleExtensions() {
        let result = handler.generateBackupName(for: "archive.tar.gz", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "archive.tar (Conflict 2025-01-14 15.30.45).gz")
    }

    func test_generateBackupName_hiddenFile() {
        let result = handler.generateBackupName(for: ".gitignore", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, ".gitignore (Conflict 2025-01-14 15.30.45)")
    }

    func test_generateBackupName_deeplyNestedPath() {
        let result = handler.generateBackupName(for: "a/b/c/d/file.txt", timestamp: "2025-01-14 15.30.45")
        XCTAssertEqual(result, "a/b/c/d/file (Conflict 2025-01-14 15.30.45).txt")
    }

    // MARK: - resolveConflicts

    func test_resolveConflicts_createsBackup() {
        // Setup: Create a file to conflict
        let filePath = (tempDir as NSString).appendingPathComponent("test.txt")
        try! "local content".write(toFile: filePath, atomically: true, encoding: .utf8)

        // Stub git show HEAD:test.txt to return the local content
        mockExecutor.stub(["show", "HEAD:test.txt"], result: .success("local content"))
        mockExecutor.stub(["checkout", "--theirs", "--", "test.txt"], result: .success())
        mockExecutor.stub(["add", "--", "test.txt"], result: .success())
        mockExecutor.stub(["-c", "core.editor=true", "merge", "--continue"], result: .success())

        let fixedDate = Date(timeIntervalSince1970: 1736870400) // 2025-01-14 12:00:00 UTC

        let result = handler.resolveConflicts(files: ["test.txt"], in: tempDir, date: fixedDate)

        guard case .success(let resolutions) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(resolutions.count, 1)
        XCTAssertEqual(resolutions[0].originalFile, "test.txt")
        XCTAssertTrue(resolutions[0].backupFile.contains("Conflict"))
        // Backup is copied to repo as backupFile, then temp file is removed
        let repoBackupPath = (tempDir as NSString).appendingPathComponent(resolutions[0].backupFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: repoBackupPath))
    }

    func test_resolveConflicts_handlesMultipleConflictsOnSameDay() {
        // Setup: Create files
        let file1Path = (tempDir as NSString).appendingPathComponent("test.txt")
        let file2Path = (tempDir as NSString).appendingPathComponent("test2.txt")
        try! "content1".write(toFile: file1Path, atomically: true, encoding: .utf8)
        try! "content2".write(toFile: file2Path, atomically: true, encoding: .utf8)

        // Stub git show commands
        mockExecutor.stub(["show", "HEAD:test.txt"], result: .success("content1"))
        mockExecutor.stub(["show", "HEAD:test2.txt"], result: .success("content2"))
        mockExecutor.stub(["checkout", "--theirs", "--", "test.txt"], result: .success())
        mockExecutor.stub(["add", "--", "test.txt"], result: .success())
        mockExecutor.stub(["checkout", "--theirs", "--", "test2.txt"], result: .success())
        mockExecutor.stub(["add", "--", "test2.txt"], result: .success())
        mockExecutor.stub(["-c", "core.editor=true", "merge", "--continue"], result: .success())

        let result = handler.resolveConflicts(files: ["test.txt", "test2.txt"], in: tempDir)

        guard case .success(let resolutions) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(resolutions.count, 2)
        // Both should have unique names (timestamp includes time)
        XCTAssertNotEqual(resolutions[0].backupPath, resolutions[1].backupPath)
    }

    func test_resolveConflicts_returnsEmptyArrayForMissingFile() {
        // No file created at tempDir - should return empty array
        mockExecutor.stub(["-c", "core.editor=true", "merge", "--continue"], result: .success())

        let result = handler.resolveConflicts(files: ["nonexistent.txt"], in: tempDir)

        guard case .success(let resolutions) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(resolutions.count, 0)
    }

    func test_resolveConflicts_preservesLocalContent() {
        let filePath = (tempDir as NSString).appendingPathComponent("data.txt")
        let localContent = "My precious local data"
        // Create the file so fileExists check passes
        try! localContent.write(toFile: filePath, atomically: true, encoding: .utf8)

        // Stub git show HEAD:data.txt to return the local content
        mockExecutor.stub(["show", "HEAD:data.txt"], result: .success(localContent))
        mockExecutor.stub(["checkout", "--theirs", "--", "data.txt"], result: .success())
        mockExecutor.stub(["add", "--", "data.txt"], result: .success())
        mockExecutor.stub(["-c", "core.editor=true", "merge", "--continue"], result: .success())

        let result = handler.resolveConflicts(files: ["data.txt"], in: tempDir)

        guard case .success(let resolutions) = result else {
            XCTFail("Expected success")
            return
        }

        XCTAssertEqual(resolutions.count, 1)
        // Verify backup file contains original content
        let backupPath = (tempDir as NSString).appendingPathComponent(resolutions[0].backupFile)
        let backupContent = try? String(contentsOfFile: backupPath, encoding: .utf8)
        XCTAssertEqual(backupContent, localContent)
    }
}
