//
//  BadgePriority.swift
//  GitRDoneShared
//

import Foundation

public enum BadgePriority: Int, Comparable {
    case clean = 0
    case untracked = 1
    case staged = 2
    case modified = 3
    case conflict = 4

    public static func < (lhs: BadgePriority, rhs: BadgePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var badgeIdentifier: String {
        switch self {
        case .clean: return ""
        case .untracked: return "Untracked"
        case .staged: return "Staged"
        case .modified: return "Modified"
        case .conflict: return "Conflict"
        }
    }

    public init(from status: GitFileStatus) {
        if status.hasConflict {
            self = .conflict
        } else if status.isModified {
            self = .modified
        } else if status.isStaged {
            self = .staged
        } else if status.isUntracked {
            self = .untracked
        } else {
            self = .clean
        }
    }
}
