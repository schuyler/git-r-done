//
//  PullResult.swift
//  GitRDoneShared
//

import Foundation

public struct PullResult: Equatable {
    public let success: Bool
    public let conflicts: [String]
    public let updatedFiles: [String]

    public init(success: Bool, conflicts: [String], updatedFiles: [String]) {
        self.success = success
        self.conflicts = conflicts
        self.updatedFiles = updatedFiles
    }

    public static func success(updatedFiles: [String] = []) -> PullResult {
        PullResult(success: true, conflicts: [], updatedFiles: updatedFiles)
    }

    public static func conflicts(_ files: [String]) -> PullResult {
        PullResult(success: false, conflicts: files, updatedFiles: [])
    }
}
