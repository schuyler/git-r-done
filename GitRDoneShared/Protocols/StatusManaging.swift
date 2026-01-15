//
//  StatusManaging.swift
//  GitRDoneShared
//

import Foundation

public protocol StatusManaging: AnyObject {
    func getCachedStatus(for repoPath: String) -> RepoStatus?
    func trackURL(_ url: URL, for repoPath: String)
    func queueRefresh(for repoPath: String)
    func invalidate(repoPath: String)
    func performAction(in repoPath: String, action: @escaping () -> Void)

    var onBadgeUpdate: ((URL, String) -> Void)? { get set }
}
