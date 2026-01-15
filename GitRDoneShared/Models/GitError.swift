//
//  GitError.swift
//  GitRDoneShared
//

import Foundation

public enum GitError: Error, Equatable {
    case notARepository
    case gitNotInstalled
    case commandFailed(String)
    case pushFailed(String)
    case pullFailed(String)
    case timedOut
    case repoNotAccessible(String)

    public var localizedDescription: String {
        switch self {
        case .notARepository:
            return "Not a Git repository"
        case .gitNotInstalled:
            return "Git is not installed. Please install Xcode Command Line Tools or Git from git-scm.com"
        case .commandFailed(let msg):
            return "Git command failed: \(msg)"
        case .pushFailed(let msg):
            return "Push failed: \(msg)"
        case .pullFailed(let msg):
            return "Pull failed: \(msg)"
        case .timedOut:
            return "Operation timed out"
        case .repoNotAccessible(let path):
            return "Repository not accessible: \(path)"
        }
    }
}
