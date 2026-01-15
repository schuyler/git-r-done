//
//  GitFileStatus.swift
//  GitRDoneShared
//

import Foundation

public enum GitStatusCode: Equatable {
    case untracked
    case modified
    case added
    case deleted
    case renamed
    case copied
    case unmerged
    case ignored
    case clean

    public init(character: Character) {
        switch character {
        case "?": self = .untracked
        case "M": self = .modified
        case "A": self = .added
        case "D": self = .deleted
        case "R": self = .renamed
        case "C": self = .copied
        case "U": self = .unmerged
        case "!": self = .ignored
        case ".", " ": self = .clean
        default: self = .clean
        }
    }
}

public struct GitFileStatus: Equatable {
    public let path: String
    public let indexStatus: GitStatusCode
    public let worktreeStatus: GitStatusCode

    public init(path: String, indexStatus: GitStatusCode, worktreeStatus: GitStatusCode) {
        self.path = path
        self.indexStatus = indexStatus
        self.worktreeStatus = worktreeStatus
    }

    public var isUntracked: Bool {
        indexStatus == .untracked && worktreeStatus == .untracked
    }

    public var isModified: Bool {
        worktreeStatus == .modified || worktreeStatus == .added || worktreeStatus == .deleted
    }

    public var isStaged: Bool {
        switch indexStatus {
        case .modified, .added, .deleted, .renamed, .copied:
            return true
        default:
            return false
        }
    }

    public var hasConflict: Bool {
        indexStatus == .unmerged || worktreeStatus == .unmerged
    }
}
