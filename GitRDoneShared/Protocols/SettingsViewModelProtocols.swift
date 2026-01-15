//
//  SettingsViewModelProtocols.swift
//  GitRDoneShared
//

import Foundation

/// Protocol for repository configuration storage
public protocol RepoConfiguring {
    var repositories: [WatchedRepository] { get }
    func add(_ repo: WatchedRepository)
    func remove(id: UUID)
    func contains(path: String) -> Bool
}

/// Protocol for app settings storage
public protocol SettingsStoring {
    var settings: AppSettings { get }
    func update(_ settings: AppSettings)
}

/// Protocol for validating Git repositories
public protocol GitValidating {
    func isGitRepository(at path: String) -> Bool
}

/// Protocol for presenting errors to the user
public protocol ErrorPresenting {
    func showError(_ message: String)
}

/// Protocol for caching repository status summaries
public protocol StatusCaching {
    var summaries: [RepoStatusSummary] { get }
    func update(_ summary: RepoStatusSummary)
    func remove(path: String)
    func summary(for path: String) -> RepoStatusSummary?
}
