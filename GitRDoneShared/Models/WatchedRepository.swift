//
//  WatchedRepository.swift
//  GitRDoneShared
//

import Foundation

public struct WatchedRepository: Codable, Identifiable, Equatable {
    public let id: UUID
    public let path: String
    public var displayName: String
    public let dateAdded: Date

    public var url: URL {
        URL(fileURLWithPath: path)
    }

    /// Creates a repository with an explicit display name.
    public init(id: UUID = UUID(), path: String, displayName: String, dateAdded: Date = Date()) {
        self.id = id
        self.path = (path as NSString).standardizingPath
        self.displayName = displayName
        self.dateAdded = dateAdded
    }

    /// Creates a repository with a default display name derived from path.
    public init(id: UUID = UUID(), path: String, dateAdded: Date = Date()) {
        let standardizedPath = (path as NSString).standardizingPath
        self.init(
            id: id,
            path: standardizedPath,
            displayName: URL(fileURLWithPath: standardizedPath).lastPathComponent,
            dateAdded: dateAdded
        )
    }
}
