//
//  RepoStatus.swift
//  GitRDoneShared
//

import Foundation

public struct RepoStatus: Equatable {
    public let repoPath: String
    public let files: [String: GitFileStatus]
    public let timestamp: Date
    public let commitsAhead: Int
    public let commitsBehind: Int

    public init(
        repoPath: String,
        files: [String: GitFileStatus],
        timestamp: Date = Date(),
        commitsAhead: Int = 0,
        commitsBehind: Int = 0
    ) {
        self.repoPath = repoPath
        self.files = files
        self.timestamp = timestamp
        self.commitsAhead = commitsAhead
        self.commitsBehind = commitsBehind
    }

    public func status(for relativePath: String) -> GitFileStatus? {
        files[relativePath]
    }
}
