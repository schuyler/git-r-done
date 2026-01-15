//
//  GitStatusParserTests.swift
//  GitRDoneSharedTests
//

import Testing
@testable import GitRDoneShared

struct GitStatusParserTests {

    // MARK: - Empty and Basic Input Tests

    @Test func parseEmptyString_returnsEmptyArray() {
        let result = GitStatusParser.parse("")
        #expect(result.isEmpty)
    }

    @Test func parseWhitespaceOnly_returnsEmptyArray() {
        let result = GitStatusParser.parse("\n\n\n")
        #expect(result.isEmpty)
    }

    // MARK: - Untracked Files (? prefix)

    @Test func parseUntrackedFile_returnsUntrackedStatus() {
        let output = "? newfile.txt"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "newfile.txt")
        #expect(result[0].indexStatus == .untracked)
        #expect(result[0].worktreeStatus == .untracked)
        #expect(result[0].isUntracked == true)
    }

    @Test func parseUntrackedFileWithSpaces_returnsCorrectPath() {
        let output = "? path with spaces/file name.txt"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "path with spaces/file name.txt")
    }

    @Test func parseMultipleUntrackedFiles_returnsAll() {
        let output = """
        ? file1.txt
        ? file2.txt
        ? file3.txt
        """
        let result = GitStatusParser.parse(output)

        #expect(result.count == 3)
        #expect(result[0].path == "file1.txt")
        #expect(result[1].path == "file2.txt")
        #expect(result[2].path == "file3.txt")
    }

    // MARK: - Ignored Files (! prefix)

    @Test func parseIgnoredFile_returnsIgnoredStatus() {
        let output = "! ignored.log"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "ignored.log")
        #expect(result[0].indexStatus == .ignored)
        #expect(result[0].worktreeStatus == .ignored)
    }

    // MARK: - Changed Entries (1 prefix - ordinary changes)

    @Test func parseModifiedInWorktree_returnsModifiedStatus() {
        // Format: 1 XY sub mH mI mW hH hI path
        // .M means clean in index, modified in worktree
        let output = "1 .M N... 100644 100644 100644 abc123 def456 modified.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "modified.swift")
        #expect(result[0].indexStatus == .clean)
        #expect(result[0].worktreeStatus == .modified)
        #expect(result[0].isModified == true)
        #expect(result[0].isStaged == false)
    }

    @Test func parseStagedModified_returnsStagedStatus() {
        // M. means modified in index (staged), clean in worktree
        let output = "1 M. N... 100644 100644 100644 abc123 def456 staged.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "staged.swift")
        #expect(result[0].indexStatus == .modified)
        #expect(result[0].worktreeStatus == .clean)
        #expect(result[0].isStaged == true)
    }

    @Test func parseStagedAndModified_returnsBothStatuses() {
        // MM means modified in index AND modified in worktree
        let output = "1 MM N... 100644 100644 100644 abc123 def456 both.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "both.swift")
        #expect(result[0].indexStatus == .modified)
        #expect(result[0].worktreeStatus == .modified)
        #expect(result[0].isStaged == true)
        #expect(result[0].isModified == true)
    }

    @Test func parseAddedFile_returnsAddedStatus() {
        // A. means added to index (staged new file)
        let output = "1 A. N... 000000 100644 100644 0000000 abc123 newfile.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "newfile.swift")
        #expect(result[0].indexStatus == .added)
        #expect(result[0].worktreeStatus == .clean)
        #expect(result[0].isStaged == true)
    }

    @Test func parseDeletedFile_returnsDeletedStatus() {
        // D. means deleted in index
        let output = "1 D. N... 100644 000000 000000 abc123 0000000 deleted.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "deleted.swift")
        #expect(result[0].indexStatus == .deleted)
        #expect(result[0].worktreeStatus == .clean)
        #expect(result[0].isStaged == true)
    }

    @Test func parseDeletedInWorktree_returnsDeletedWorktreeStatus() {
        // .D means deleted in worktree (not staged)
        let output = "1 .D N... 100644 100644 000000 abc123 abc123 deleted_local.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "deleted_local.swift")
        #expect(result[0].indexStatus == .clean)
        #expect(result[0].worktreeStatus == .deleted)
        #expect(result[0].isModified == true)
    }

    @Test func parsePathWithSpaces_handlesCorrectly() {
        let output = "1 M. N... 100644 100644 100644 abc123 def456 path with spaces/my file.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "path with spaces/my file.swift")
    }

    // MARK: - Renamed Files (2 prefix)

    @Test func parseRenamedFile_returnsRenamedStatus() {
        // Format: 2 XY sub mH mI mW hH hI Xscore path\torigPath
        let output = "2 R. N... 100644 100644 100644 abc123 abc123 R100 newname.swift\toldname.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "newname.swift")
        #expect(result[0].indexStatus == .renamed)
        #expect(result[0].worktreeStatus == .clean)
        #expect(result[0].isStaged == true)
    }

    @Test func parseCopiedFile_returnsCopiedStatus() {
        // C. means copied in index
        let output = "2 C. N... 100644 100644 100644 abc123 abc123 C100 copy.swift\toriginal.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "copy.swift")
        #expect(result[0].indexStatus == .copied)
        #expect(result[0].worktreeStatus == .clean)
        #expect(result[0].isStaged == true)
    }

    // MARK: - Unmerged Files (u prefix - conflicts)

    @Test func parseUnmergedFile_returnsUnmergedStatus() {
        // Format: u XY sub m1 m2 m3 mW h1 h2 h3 path
        let output = "u UU N... 100644 100644 100644 100644 abc123 def456 ghi789 conflicted.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "conflicted.swift")
        #expect(result[0].indexStatus == .unmerged)
        #expect(result[0].worktreeStatus == .unmerged)
        #expect(result[0].hasConflict == true)
    }

    @Test func parseUnmergedFileWithSpaces_handlesCorrectly() {
        let output = "u UU N... 100644 100644 100644 100644 abc123 def456 ghi789 path with spaces/conflict file.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "path with spaces/conflict file.swift")
        #expect(result[0].hasConflict == true)
    }

    // MARK: - Mixed Status Output

    @Test func parseMixedStatus_returnsAllEntries() {
        let output = """
        1 M. N... 100644 100644 100644 abc123 def456 staged.swift
        1 .M N... 100644 100644 100644 abc123 def456 modified.swift
        ? untracked.txt
        ! ignored.log
        u UU N... 100644 100644 100644 100644 abc123 def456 ghi789 conflict.swift
        """
        let result = GitStatusParser.parse(output)

        #expect(result.count == 5)

        #expect(result[0].path == "staged.swift")
        #expect(result[0].isStaged == true)

        #expect(result[1].path == "modified.swift")
        #expect(result[1].isModified == true)

        #expect(result[2].path == "untracked.txt")
        #expect(result[2].isUntracked == true)

        #expect(result[3].path == "ignored.log")
        #expect(result[3].indexStatus == .ignored)

        #expect(result[4].path == "conflict.swift")
        #expect(result[4].hasConflict == true)
    }

    // MARK: - Edge Cases

    @Test func parseUnknownPrefix_ignoresLine() {
        let output = "X unknown line format"
        let result = GitStatusParser.parse(output)

        #expect(result.isEmpty)
    }

    @Test func parseMalformedChangedEntry_ignoresLine() {
        // Too few parts
        let output = "1 M. N..."
        let result = GitStatusParser.parse(output)

        #expect(result.isEmpty)
    }

    @Test func parseMalformedXYCode_ignoresLine() {
        // XY code should be exactly 2 characters
        let output = "1 M N... 100644 100644 100644 abc123 def456 file.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.isEmpty)
    }

    // MARK: - Additional Renamed/Copied Edge Cases

    @Test func parseRenamedFileWithSpaces_handlesCorrectly() {
        let output = "2 R. N... 100644 100644 100644 abc123 abc123 R100 new file name.swift\told file name.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "new file name.swift")
        #expect(result[0].indexStatus == .renamed)
    }

    @Test func parseRenamedAndModified_returnsBothStatuses() {
        // RM means renamed in index AND modified in worktree
        let output = "2 RM N... 100644 100644 100644 abc123 def456 R100 renamed.swift\toriginal.swift"
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "renamed.swift")
        #expect(result[0].indexStatus == .renamed)
        #expect(result[0].worktreeStatus == .modified)
    }

    // MARK: - Header Lines (porcelain v2 can include these)

    @Test func parseHeaderLines_ignoresHeaders() {
        let output = """
        # branch.oid abc123def456
        # branch.head main
        ? newfile.txt
        """
        let result = GitStatusParser.parse(output)

        #expect(result.count == 1)
        #expect(result[0].path == "newfile.txt")
    }

    // MARK: - parseUpdatedFiles Tests

    @Test func parseUpdatedFiles_emptyString_returnsEmptyArray() {
        let result = GitStatusParser.parseUpdatedFiles("")
        #expect(result.isEmpty)
    }

    @Test func parseUpdatedFiles_singleFile_returnsArray() {
        let output = "file.txt"
        let result = GitStatusParser.parseUpdatedFiles(output)

        #expect(result.count == 1)
        #expect(result[0] == "file.txt")
    }

    @Test func parseUpdatedFiles_multipleFiles_returnsAll() {
        let output = """
        file1.txt
        file2.swift
        path/to/file3.md
        """
        let result = GitStatusParser.parseUpdatedFiles(output)

        #expect(result.count == 3)
        #expect(result[0] == "file1.txt")
        #expect(result[1] == "file2.swift")
        #expect(result[2] == "path/to/file3.md")
    }

    @Test func parseUpdatedFiles_withEmptyLines_filtersEmptyLines() {
        let output = """
        file1.txt

        file2.txt

        """
        let result = GitStatusParser.parseUpdatedFiles(output)

        #expect(result.count == 2)
        #expect(result[0] == "file1.txt")
        #expect(result[1] == "file2.txt")
    }

    @Test func parseUpdatedFiles_withSpaces_preservesSpaces() {
        let output = "path with spaces/file name.txt"
        let result = GitStatusParser.parseUpdatedFiles(output)

        #expect(result.count == 1)
        #expect(result[0] == "path with spaces/file name.txt")
    }

    // MARK: - Order Preservation

    @Test func parse_preservesOrder() {
        let output = """
        ? z_last.txt
        ? a_first.txt
        ? m_middle.txt
        """
        let result = GitStatusParser.parse(output)

        #expect(result.count == 3)
        #expect(result[0].path == "z_last.txt")
        #expect(result[1].path == "a_first.txt")
        #expect(result[2].path == "m_middle.txt")
    }

    // MARK: - Branch Ahead/Behind Tests

    @Test func parseBranchAb_parsesAheadBehind() {
        let output = """
        # branch.ab +2 -1
        """
        let branchInfo = GitStatusParser.parseBranchInfo(output)
        #expect(branchInfo.ahead == 2)
        #expect(branchInfo.behind == 1)
    }

    @Test func parseBranchAb_zeros() {
        let output = "# branch.ab +0 -0"
        let branchInfo = GitStatusParser.parseBranchInfo(output)
        #expect(branchInfo.ahead == 0)
        #expect(branchInfo.behind == 0)
    }

    @Test func parseBranchAb_missingLine() {
        let output = "# branch.head main\n? file.txt"
        let branchInfo = GitStatusParser.parseBranchInfo(output)
        #expect(branchInfo.ahead == 0)
        #expect(branchInfo.behind == 0)
    }
}
