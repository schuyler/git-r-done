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
        self.path = (path as NSString).standardizingPath
        self.displayName = URL(fileURLWithPath: path).lastPathComponent
        self.dateAdded = dateAdded
    }
}
