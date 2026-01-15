//
//  GitOperations.swift
//  GitRDoneShared
//

import Foundation

public final class GitOperations {

    private let executor: GitExecuting

    public init(executor: GitExecuting = ShellGitExecutor()) {
        self.executor = executor
    }

    public func isGitAvailable() -> Bool {
        executor.isGitAvailable()
    }

    public func isGitRepository(at path: String) -> Bool {
        let result = executor.execute(["rev-parse", "--git-dir"], in: path)
        return result.success
    }

    public func getStatus(in repoPath: String) -> Result<[GitFileStatus], GitError> {
        guard FileManager.default.fileExists(atPath: repoPath) else {
            return .failure(.repoNotAccessible(repoPath))
        }

        let result = executor.execute(["status", "--porcelain=v2"], in: repoPath)

        if result == .gitNotFound {
            return .failure(.gitNotInstalled)
        }

        if result == .timedOut {
            return .failure(.timedOut)
        }

        guard result.success else {
            if result.stderr.contains("not a git repository") {
                return .failure(.notARepository)
            }
            return .failure(.commandFailed(result.stderr))
        }

        let statuses = GitStatusParser.parse(result.stdout)
        return .success(statuses)
    }

    public func stage(file: String, in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["add", "--", file], in: repoPath)

        if !result.success {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }

    public func unstage(file: String, in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["restore", "--staged", "--", file], in: repoPath)

        if !result.success {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }

    public func revert(file: String, in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["restore", "--", file], in: repoPath)

        if !result.success {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }

    public func commit(message: String, in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["commit", "-m", message], in: repoPath)

        if !result.success {
            return .failure(.commandFailed(result.stderr))
        }
        return .success(())
    }

    public func commitFile(_ file: String, message: String, in repoPath: String) -> Result<Void, GitError> {
        // Stage the file first
        if case .failure(let error) = stage(file: file, in: repoPath) {
            return .failure(error)
        }

        return commit(message: message, in: repoPath)
    }

    public func commitAll(message: String, in repoPath: String) -> Result<Void, GitError> {
        let addResult = executor.execute(["add", "-A"], in: repoPath)
        if !addResult.success {
            return .failure(.commandFailed(addResult.stderr))
        }

        return commit(message: message, in: repoPath)
    }

    public func push(in repoPath: String) -> Result<Void, GitError> {
        let result = executor.execute(["push"], in: repoPath, timeout: 60)

        if result == .timedOut {
            return .failure(.timedOut)
        }

        if !result.success {
            return .failure(.pushFailed(result.stderr))
        }
        return .success(())
    }

    public func pull(in repoPath: String) -> Result<PullResult, GitError> {
        // Get list of files before pull
        let beforeResult = executor.execute(["rev-parse", "HEAD"], in: repoPath)
        let beforeHead = beforeResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

        let pullResult = executor.execute(["pull"], in: repoPath, timeout: 60)

        if pullResult == .timedOut {
            return .failure(.timedOut)
        }

        // Check for conflicts
        if !pullResult.success {
            if pullResult.stderr.contains("CONFLICT") || pullResult.stdout.contains("CONFLICT") {
                let conflictFiles = parseConflictFiles(pullResult.stdout + pullResult.stderr)
                return .success(.conflicts(conflictFiles))
            }
            return .failure(.pullFailed(pullResult.stderr))
        }

        // Get list of updated files
        if !beforeHead.isEmpty {
            let diffResult = executor.execute(["diff", "--name-only", beforeHead, "HEAD"], in: repoPath)
            if diffResult.success {
                let updatedFiles = GitStatusParser.parseUpdatedFiles(diffResult.stdout)
                return .success(.success(updatedFiles: updatedFiles))
            }
        }

        return .success(.success())
    }

    public func acceptTheirsAndComplete(files: [String], in repoPath: String) -> Result<Void, GitError> {
        for file in files {
            let checkoutResult = executor.execute(["checkout", "--theirs", "--", file], in: repoPath)
            if !checkoutResult.success {
                return .failure(.commandFailed(checkoutResult.stderr))
            }

            let addResult = executor.execute(["add", "--", file], in: repoPath)
            if !addResult.success {
                return .failure(.commandFailed(addResult.stderr))
            }
        }

        // Complete the merge
        let commitResult = executor.execute(["-c", "core.editor=true", "merge", "--continue"], in: repoPath)
        if !commitResult.success {
            // Try commit instead if merge --continue fails
            let altCommit = executor.execute(["commit", "--no-edit"], in: repoPath)
            if !altCommit.success {
                return .failure(.commandFailed(altCommit.stderr))
            }
        }

        return .success(())
    }

    public func getRepoName(at path: String) -> String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    private func parseConflictFiles(_ output: String) -> [String] {
        var files: [String] = []
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            // Look for "CONFLICT (content): Merge conflict in <file>"
            if line.contains("Merge conflict in ") {
                if let range = line.range(of: "Merge conflict in ") {
                    let file = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                    files.append(file)
                }
            }
        }

        return files
    }
}
