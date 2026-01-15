//
//  RepoStatus.swift
//  GitRDoneShared
//

import Foundation

public struct RepoStatus: Equatable {
    public let repoPath: String
    public let files: [String: GitFileStatus]
    public let timestamp: Date

    public init(repoPath: String, files: [String: GitFileStatus], timestamp: Date = Date()) {
        self.repoPath = repoPath
        self.files = files
        self.timestamp = timestamp
    }

    public func status(for relativePath: String) -> GitFileStatus? {
        files[relativePath]
    }
}
