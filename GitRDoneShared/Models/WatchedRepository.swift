//
//  WatchedRepository.swift
//  GitRDoneShared
//

import Foundation

public struct WatchedRepository: Codable, Identifiable, Equatable {
    public let id: UUID
    public let path: String
    public let displayName: String
    public let dateAdded: Date

    public var url: URL {
        URL(fileURLWithPath: path)
    }

    public init(id: UUID = UUID(), path: String, dateAdded: Date = Date()) {
        self.id = id
        let standardizedPath = (path as NSString).standardizingPath
        self.path = standardizedPath
        self.displayName = URL(fileURLWithPath: standardizedPath).lastPathComponent
        self.dateAdded = dateAdded
    }
}
