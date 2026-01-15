//
//  RepoStatusSummary.swift
//  GitRDoneShared
//

import Foundation

public struct RepoStatusSummary: Codable, Equatable {
    public let path: String
    public let status: BadgePriority
    public let commitsAhead: Int
    public let updatedAt: Date

    public init(path: String, status: BadgePriority, commitsAhead: Int = 0, updatedAt: Date = Date()) {
        self.path = path
        self.status = status
        self.commitsAhead = commitsAhead
        self.updatedAt = updatedAt
    }

    public var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
