//
//  GitStatusParser.swift
//  GitRDoneShared
//

import Foundation

public enum GitStatusParser {

    /// Parses output from `git status --porcelain=v2`
    public static func parse(_ output: String) -> [GitFileStatus] {
        var results: [GitFileStatus] = []

        for line in output.components(separatedBy: "\n") {
            guard !line.isEmpty else { continue }

            if line.hasPrefix("1 ") || line.hasPrefix("2 ") {
                // Changed entry: "1 XY ... path" or "2 XY ... path" (rename)
                if let status = parseChangedEntry(line) {
                    results.append(status)
                }
            } else if line.hasPrefix("? ") {
                // Untracked: "? path"
                let path = String(line.dropFirst(2))
                results.append(GitFileStatus(
                    path: path,
                    indexStatus: .untracked,
                    worktreeStatus: .untracked
                ))
            } else if line.hasPrefix("! ") {
                // Ignored: "! path"
                let path = String(line.dropFirst(2))
                results.append(GitFileStatus(
                    path: path,
                    indexStatus: .ignored,
                    worktreeStatus: .ignored
                ))
            } else if line.hasPrefix("u ") {
                // Unmerged entry: "u XY ... path"
                if let status = parseUnmergedEntry(line) {
                    results.append(status)
                }
            }
        }

        return results
    }

    private static func parseChangedEntry(_ line: String) -> GitFileStatus? {
        // Format: "1 XY sub mH mI mW hH hI path"
        // or:     "2 XY sub mH mI mW hH hI X path\torigPath"
        let parts = line.components(separatedBy: " ")
        guard parts.count >= 9 else { return nil }

        let xy = parts[1]
        guard xy.count == 2 else { return nil }

        let indexChar = xy.first!
        let worktreeChar = xy.last!

        // For renamed files, path is at index 9 and may contain a tab
        let pathStartIndex = 8
        var path = parts[pathStartIndex...].joined(separator: " ")

        // Handle renamed files (type 2) - path format is "newPath\toldPath"
        if line.hasPrefix("2 "), let tabIndex = path.firstIndex(of: "\t") {
            path = String(path[..<tabIndex])
        }

        return GitFileStatus(
            path: path,
            indexStatus: GitStatusCode(character: indexChar),
            worktreeStatus: GitStatusCode(character: worktreeChar)
        )
    }

    private static func parseUnmergedEntry(_ line: String) -> GitFileStatus? {
        // Format: "u XY sub m1 m2 m3 mW h1 h2 h3 path"
        let parts = line.components(separatedBy: " ")
        guard parts.count >= 11 else { return nil }

        let path = parts[10...].joined(separator: " ")

        return GitFileStatus(
            path: path,
            indexStatus: .unmerged,
            worktreeStatus: .unmerged
        )
    }

    /// Parses output from `git diff --name-only` to get list of updated files
    public static func parseUpdatedFiles(_ output: String) -> [String] {
        output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
    }
}
